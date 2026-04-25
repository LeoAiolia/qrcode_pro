import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ImageImportButton: View {
    let isLoading: Bool
    let onImageSelected: (CGImage) -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openImage()
            } label: {
                Label(isLoading ? "识别中" : "选择图片", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppTheme.warning)
            }
        }
    }

    private func openImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        let response = panel.runModal()
        guard isConfirmed(response), let url = panel.url else {
            return
        }

        guard
            let image = NSImage(contentsOf: url),
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            errorMessage = ImageRecognitionError.invalidImage.localizedDescription
            return
        }

        errorMessage = nil
        onImageSelected(cgImage)
    }

    private func isConfirmed(_ response: NSApplication.ModalResponse) -> Bool {
        switch response {
        case .OK:
            return true
        case .cancel, .abort, .continue, .stop:
            return false
        default:
            return false
        }
    }
}
