import AppKit
import SwiftUI

struct ShareImageButton: View {
    let image: PlatformImage
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                saveImage()
            } label: {
                Label("保存二维码", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppTheme.warning)
            }
        }
    }

    private func saveImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "QRScan-Pro.png"

        guard isConfirmed(panel.runModal()), let url = panel.url else {
            return
        }

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            errorMessage = QRCodeGenerationError.imageRenderFailed.localizedDescription
            return
        }

        do {
            try pngData.write(to: url)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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
