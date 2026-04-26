import SwiftUI
import UIKit

/// 包装 UIActivityViewController；接受任意可分享对象（UIImage / NSURL / String / Data）。
struct ShareItemsButton<Label: View>: View {
    let items: [Any]
    @ViewBuilder var label: () -> Label

    @State private var presented = false

    var body: some View {
        Button {
            presented = true
        } label: {
            label()
        }
        .sheet(isPresented: $presented) {
            ActivityRepresentable(items: items)
        }
    }
}

private struct ActivityRepresentable: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
