import SwiftUI

struct ScannerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedResult: ScanResult?
    @State private var errorMessage: String?
    @State private var isRecognizingImage = false

    private let capability = PlatformCapability()
    private let recognizer = BarcodeImageRecognizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                #if os(iOS)
                if capability.supportsCameraScanning {
                    LiveScannerContainer { result in
                        handle(result: result)
                    } onError: { message in
                        errorMessage = message
                        store.logger.error(message)
                    }
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                #endif

                ImageImportPanel(
                    isLoading: isRecognizingImage,
                    onImageSelected: { cgImage in
                        recognizeImage(cgImage)
                    }
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(AppTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .cardBackground()
                }

                #if os(macOS)
                Text("macOS 版仅支持二维码图片识别，可将包含二维码的图片导入识别。")
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                #endif
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(AppTab.scanner.title)
        .sheet(item: $selectedResult) { result in
            NavigationView {
                ScanResultView(result: result)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QRScan Pro")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerSubtitle: String {
        #if os(macOS)
        return "导入图片识别二维码内容"
        #else
        return capability.supportsCameraScanning ? "将二维码放入框内自动识别" : "当前设备不支持相机扫码，请使用图片识别"
        #endif
    }

    private func recognizeImage(_ cgImage: CGImage) {
        isRecognizingImage = true
        errorMessage = nil

        Task {
            do {
                let result = try await recognizer.recognize(cgImage: cgImage)
                await MainActor.run {
                    handle(result: result)
                    isRecognizingImage = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRecognizingImage = false
                    store.logger.error(error.localizedDescription)
                }
            }
        }
    }

    private func handle(result: ScanResult) {
        guard isAllowed(kind: result.kind) else {
            store.logger.warning("识别结果已被码制设置过滤：\(result.kind.displayName)")
            return
        }

        store.addResult(result)
        selectedResult = result
    }

    private func isAllowed(kind: BarcodeKind) -> Bool {
        switch kind {
        case .unknown:
            return true
        case .qr, .ean13, .ean8, .upce, .code128, .code39, .pdf417, .aztec, .dataMatrix:
            return store.settings.enabledKinds.contains(kind)
        }
    }
}

struct ImageImportPanel: View {
    let isLoading: Bool
    let onImageSelected: (CGImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("图片识别", systemImage: "photo.on.rectangle")
                .font(.headline)
                .foregroundColor(.white)

            Text("选择包含二维码或条形码的图片，应用会在本地完成识别。")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)

            ImageImportButton(isLoading: isLoading, onImageSelected: onImageSelected)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardBackground()
    }
}
