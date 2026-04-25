import SwiftUI

struct ScanResultView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let result: ScanResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                metaRow
                rawValueCard

                if let url = result.url {
                    urlCard(url)
                }

                actionGrid
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("扫描结果")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: closePlacement) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Text(result.kind.displayName)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.18))
                .foregroundColor(AppTheme.accent)
                .clipShape(Capsule())

            Text(result.source.displayName)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceRaised)
                .foregroundColor(.white)
                .clipShape(Capsule())

            Text(result.createdAt.formatted(date: .omitted, time: .shortened))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceRaised)
                .foregroundColor(AppTheme.textSecondary)
                .clipShape(Capsule())
        }
        .font(.caption)
    }

    private var rawValueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("原始内容")
                .font(.headline)
                .foregroundColor(.white)

            Text(result.value)
                .font(.body.monospaced())
                .foregroundColor(.white)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .cardBackground()
    }

    private func urlCard(_ url: URL) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "safari")
                .foregroundColor(AppTheme.accent)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("检测到网页链接")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(url.host ?? url.absoluteString)
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Button("打开") {
                openURL(url)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .cardBackground()
    }

    private var actionGrid: some View {
        VStack(spacing: 12) {
            Button {
                ClipboardService.copy(result.value)
                store.logger.info("复制扫描结果")
            } label: {
                Label("复制内容", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                store.deleteResult(result)
                dismiss()
            } label: {
                Label("删除记录", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var closePlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    private func openURL(_ url: URL) {
        #if os(iOS)
        SafariPresenter.present(url: url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
        store.logger.info("打开链接：\(url.absoluteString)")
    }
}
