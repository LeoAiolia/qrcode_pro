import SwiftData
import SwiftUI

#if os(iOS)
import PhotosUI

/// 全屏扫码主页：相机预览铺底，SwiftUI 叠加扫描框 / 闪光灯 / 相册 / 连续模式 Toast。
struct ScannerView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var isTorchOn = false
    @State private var pickerPresented = false
    @State private var generatorPresented = false
    @State private var pushedRecord: ScanRecord?
    @State private var errorMessage: String?
    @State private var toastMessage: String?
    @State private var lastValue: String?
    @State private var lastValueAt: Date = .distantPast

    private let capability = PlatformCapability()
    private let recognizer = BarcodeImageRecognizer()
    private let dedupInterval: TimeInterval = 1.5

    var body: some View {
        ZStack {
            if capability.supportsCameraScanning {
                LiveScannerContainer(
                    isTorchOn: $isTorchOn,
                    onResult: handle(result:),
                    onError: { message in errorMessage = message }
                )
                .ignoresSafeArea()

                ScannerOverlay(isContinuous: settings.continuousScanEnabled)
                    .ignoresSafeArea()

                bottomControls
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.xxl)
            } else {
                noCameraFallback
            }

            if let toastMessage {
                Text(toastMessage)
                    .font(AppFont.footnote)
                    .padding(.horizontal, Spacing.l)
                    .padding(.vertical, Spacing.s)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundColor(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.top, Spacing.xxxl)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.footnote)
                    .padding(Spacing.m)
                    .background(AppColor.danger.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m))
                    .padding(Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $pushedRecord) { record in
            ScanResultView(record: record)
        }
        .navigationDestination(isPresented: $generatorPresented) {
            GeneratorView()
        }
        .sheet(isPresented: $pickerPresented) {
            PhotoPicker { result in
                switch result {
                case .success(let cgImage):
                    Task { await recognizeImage(cgImage) }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                isTorchOn = false
            }
        }
        .onDisappear {
            isTorchOn = false
        }
        .animation(.easeInOut(duration: 0.25), value: toastMessage)
    }

    private var bottomControls: some View {
        HStack(spacing: Spacing.xxxl) {
            controlButton(systemImage: "photo.on.rectangle", label: "相册") {
                pickerPresented = true
            }
            .accessibilityLabel("从相册选择图片识别")

            controlButton(systemImage: "qrcode", label: "生成") {
                generatorPresented = true
            }
            .accessibilityLabel("生成二维码")

            if capability.supportsTorch {
                controlButton(
                    systemImage: isTorchOn ? "bolt.fill" : "bolt",
                    label: isTorchOn ? "关灯" : "开灯",
                    tint: isTorchOn ? AppColor.warning : .white
                ) {
                    isTorchOn.toggle()
                }
                .accessibilityLabel(isTorchOn ? "关闭闪光灯" : "打开闪光灯")
            }
        }
    }

    private func controlButton(
        systemImage: String,
        label: String,
        tint: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(label)
                    .font(AppFont.caption)
            }
            .foregroundColor(tint)
            .frame(width: 64, height: 64)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.l))
        }
        .buttonStyle(.plain)
    }

    private var noCameraFallback: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppColor.textSecondary)
            Text("当前设备不支持相机扫码")
                .font(AppFont.headline)
                .foregroundColor(AppColor.textPrimary)
            Button {
                pickerPresented = true
            } label: {
                Label("从相册选择图片识别", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, Spacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
    }

    // MARK: - Result handling

    private func handle(result: RecognizedCode) {
        guard settings.enabledKinds.contains(result.kind) else {
            DebugLogger.shared.warning("识别结果被码制设置过滤：\(result.kind.displayName)")
            return
        }

        let now = Date()
        if let last = lastValue, last == result.value, now.timeIntervalSince(lastValueAt) < dedupInterval {
            return
        }
        lastValue = result.value
        lastValueAt = now

        let record = ScanRecord(value: result.value, kind: result.kind, source: result.source)
        do {
            modelContext.insert(record)
            try modelContext.save()
        } catch {
            errorMessage = "扫描结果保存失败：\(error.localizedDescription)"
            return
        }

        HapticFeedback.scanSuccess(
            vibrate: settings.vibrationEnabled,
            sound: settings.soundEnabled
        )

        if settings.continuousScanEnabled {
            showToast("已识别：\(result.value)")
        } else {
            pushedRecord = record
        }
    }

    private func recognizeImage(_ cgImage: CGImage) async {
        do {
            let code = try await recognizer.recognize(
                cgImage: cgImage,
                allowedKinds: settings.enabledKinds
            )
            handle(result: code)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

private struct PhotoPicker: UIViewControllerRepresentable {
    let completion: (Result<CGImage, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (Result<CGImage, Error>) -> Void

        init(completion: @escaping (Result<CGImage, Error>) -> Void) {
            self.completion = completion
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                return
            }

            guard provider.canLoadObject(ofClass: UIImage.self) else {
                completion(.failure(ImageRecognitionError.invalidImage))
                return
            }

            provider.loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    DispatchQueue.main.async {
                        self.completion(.failure(error))
                    }
                    return
                }

                guard let image = object as? UIImage, let cgImage = image.cgImage else {
                    DispatchQueue.main.async {
                        self.completion(.failure(ImageRecognitionError.invalidImage))
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.completion(.success(cgImage))
                }
            }
        }
    }
}

#else

/// macOS 不直接使用 ScannerView，由 MacImageRecognitionView 接管图片识别。
struct ScannerView: View {
    var body: some View {
        MacImageRecognitionView()
    }
}

#endif
