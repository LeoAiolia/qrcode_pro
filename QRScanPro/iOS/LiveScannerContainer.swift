import AVFoundation
import SwiftUI
import UIKit
import Vision

struct LiveScannerContainer: UIViewControllerRepresentable {
    let onResult: (ScanResult) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        ScannerViewController(onResult: onResult, onError: onError)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let onResult: (ScanResult) -> Void
    private let onError: (String) -> Void
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isHandlingResult = false

    init(onResult: @escaping (ScanResult) -> Void, onError: @escaping (String) -> Void) {
        self.onResult = onResult
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
        turnTorchOff()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !isHandlingResult else {
            return
        }

        guard
            let metadata = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
            let value = metadata.stringValue
        else {
            return
        }

        isHandlingResult = true
        let result = ScanResult(value: value, kind: BarcodeKind(metadataType: metadata.type), source: .camera)

        DispatchQueue.main.async {
            self.onResult(result)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isHandlingResult = false
        }
    }

    private func configureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            buildSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    if isGranted {
                        self?.buildSession()
                    } else {
                        self?.onError("相机权限未授权")
                    }
                }
            }
        case .denied, .restricted:
            onError("相机权限未授权")
        @unknown default:
            onError("相机权限状态未知")
        }
    }

    private func buildSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            onError("当前设备不支持相机扫码")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = output.availableMetadataObjectTypes.filter { type in
                    ScannerMetadata.supportedTypes.contains(type)
                }
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer

            addOverlay()
        } catch {
            onError("相机初始化失败：\(error.localizedDescription)")
        }
    }

    private func addOverlay() {
        let label = UILabel()
        label.text = "将二维码放入框内自动识别"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28)
        ])
    }

    private func turnTorchOff() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            onError("闪光灯关闭失败：\(error.localizedDescription)")
        }
    }
}

enum ScannerMetadata {
    static let supportedTypes: [AVMetadataObject.ObjectType] = [
        .qr,
        .ean13,
        .ean8,
        .upce,
        .code128,
        .code39,
        .pdf417,
        .aztec,
        .dataMatrix
    ]
}

extension BarcodeKind {
    init(metadataType: AVMetadataObject.ObjectType) {
        switch metadataType {
        case .qr:
            self = .qr
        case .ean13:
            self = .ean13
        case .ean8:
            self = .ean8
        case .upce:
            self = .upce
        case .code128:
            self = .code128
        case .code39:
            self = .code39
        case .pdf417:
            self = .pdf417
        case .aztec:
            self = .aztec
        case .dataMatrix:
            self = .dataMatrix
        default:
            self = .unknown
        }
    }
}
