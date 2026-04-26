#if os(iOS)
import SwiftUI
import UIKit
import WebKit

/// iOS 内置浏览器；只读地址栏 / 前后退 / 下拉刷新 / 在浏览器中打开。
struct InAppBrowserView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var displayURL: URL
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var navigationAction: WebViewAction?

    init(url: URL) {
        self.url = url
        self._displayURL = State(initialValue: url)
    }

    var body: some View {
        VStack(spacing: 0) {
            addressBar

            WebViewRepresentable(
                url: url,
                action: $navigationAction,
                displayURL: $displayURL,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading
            )

            bottomBar
        }
        .navigationTitle(displayURL.host ?? "网页")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Label("在浏览器中打开", systemImage: "safari")
                    }
                    Button {
                        UIPasteboard.general.string = displayURL.absoluteString
                    } label: {
                        Label("复制链接", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("更多操作")
            }
        }
    }

    private var addressBar: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: displayURL.scheme == "https" ? "lock.fill" : "globe")
                .font(.footnote)
                .foregroundColor(AppColor.textSecondary)
            Text(displayURL.absoluteString)
                .font(AppFont.footnote)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if isLoading {
                ProgressView().scaleEffect(0.7)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .background(AppColor.surface)
    }

    private var bottomBar: some View {
        HStack(spacing: Spacing.xxl) {
            Button { navigationAction = .back } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("后退")
            .disabled(!canGoBack)

            Button { navigationAction = .forward } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("前进")
            .disabled(!canGoForward)

            Spacer()

            Button { navigationAction = .reload } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("刷新页面")
        }
        .font(.title3)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.s)
        .background(AppColor.surface)
    }
}

enum WebViewAction: Equatable {
    case back
    case forward
    case reload
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var action: WebViewAction?
    @Binding var displayURL: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let action = action else { return }
        DispatchQueue.main.async {
            self.action = nil
        }
        switch action {
        case .back:
            if webView.canGoBack { webView.goBack() }
        case .forward:
            if webView.canGoForward { webView.goForward() }
        case .reload:
            webView.reload()
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        weak var webView: WKWebView?

        init(parent: WebViewRepresentable) {
            self.parent = parent
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
            sender.endRefreshing()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            sync(webView: webView, isLoading: true)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            sync(webView: webView, isLoading: false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            sync(webView: webView, isLoading: false)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            sync(webView: webView, isLoading: false)
        }

        private func sync(webView: WKWebView, isLoading: Bool) {
            DispatchQueue.main.async {
                self.parent.isLoading = isLoading
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                if let url = webView.url {
                    self.parent.displayURL = url
                }
            }
        }
    }
}
#endif
