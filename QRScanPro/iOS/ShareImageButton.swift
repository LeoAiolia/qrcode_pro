import SwiftUI
import UIKit

struct ShareImageButton: View {
    let image: PlatformImage
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("分享二维码", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .sheet(isPresented: $isPresented) {
            ActivityView(activityItems: [image])
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
