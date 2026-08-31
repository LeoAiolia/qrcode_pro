import CoreGraphics
import Foundation
import Vision

#if targetEnvironment(simulator)
import CoreImage
#endif

enum ImageRecognitionError: LocalizedError {
    case noBarcode
    case noEnabledKind
    case invalidImage
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .noBarcode:
            return L10n.t("未在图片中识别到二维码或条形码")
        case .noEnabledKind:
            return L10n.t("请先在设置中启用至少一种码制")
        case .invalidImage:
            return L10n.t("图片无法读取")
        case .requestFailed(let message):
            return String(format: L10n.t("图片识别失败：%@"), message)
        }
    }
}

struct BarcodeImageRecognizer {
    /// 单码识别：取首个匹配 allowedKinds 的结果。
    func recognize(cgImage: CGImage, allowedKinds: Set<BarcodeKind>) async throws -> RecognizedCode {
        let codes = try await recognizeAll(cgImage: cgImage, allowedKinds: allowedKinds)
        guard let first = codes.first else {
            throw ImageRecognitionError.noBarcode
        }
        return first
    }

    /// 多码识别：返回图片中所有命中 allowedKinds 的结果，供 macOS 批量识别使用。
    func recognizeAll(cgImage: CGImage, allowedKinds: Set<BarcodeKind>) async throws -> [RecognizedCode] {
        let allowedSymbologies = allowedKinds.compactMap { $0.visionSymbology }
        guard !allowedSymbologies.isEmpty else {
            throw ImageRecognitionError.noEnabledKind
        }

        do {
            return try await detectWithVision(cgImage: cgImage, symbologies: allowedSymbologies)
        } catch {
            #if targetEnvironment(simulator)
            // 模拟器上 Vision 条码检测走 ML 推理管线，创建 inference context 会失败
            //（com.apple.Vision Code=9 / VNErrorNotImplemented），此处降级到纯 CPU 的
            // CIDetector 识别 QR，保证模拟器可调试；真机行为不受影响。
            if allowedKinds.contains(.qr) {
                await DebugLogger.shared.warning("Vision 识别失败，模拟器降级 CIDetector：\(error.localizedDescription)")
                return detectQRCodesWithCoreImage(cgImage: cgImage)
            }
            #endif
            throw error
        }
    }

    #if targetEnvironment(simulator)
    /// 模拟器专用兜底：CIDetector 仅支持 QR 码。
    private func detectQRCodesWithCoreImage(cgImage: CGImage) -> [RecognizedCode] {
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        ) else {
            return []
        }

        let features = detector.features(in: CIImage(cgImage: cgImage), options: nil)
        return features.compactMap { feature in
            guard let qrFeature = feature as? CIQRCodeFeature,
                  let message = qrFeature.messageString else {
                return nil
            }
            return RecognizedCode(value: message, kind: .qr, source: .image)
        }
    }
    #endif

    private func detectWithVision(cgImage: CGImage, symbologies: [VNBarcodeSymbology]) async throws -> [RecognizedCode] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[RecognizedCode], Error>) in
            // Vision 的 completion handler 与 perform 的抛错路径可能被重复触发
            //（尤其处理大图/异常图片失败时），需保证 continuation 只 resume 一次，
            // 否则 Swift 运行时抛 “resume a continuation twice” 致命错误导致崩溃。
            var didResume = false
            func resumeOnce(with result: Result<[RecognizedCode], Error>) {
                guard !didResume else { return }
                didResume = true
                switch result {
                case .success(let codes):
                    continuation.resume(returning: codes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    resumeOnce(with: .failure(ImageRecognitionError.requestFailed(error.localizedDescription)))
                    return
                }

                let observations = (request.results as? [VNBarcodeObservation]) ?? []
                let codes: [RecognizedCode] = observations.compactMap { observation in
                    guard
                        let value = observation.payloadStringValue,
                        let kind = BarcodeKind(symbology: observation.symbology)
                    else {
                        return nil
                    }
                    return RecognizedCode(value: value, kind: kind, source: .image)
                }
                resumeOnce(with: .success(codes))
            }
            request.symbologies = symbologies

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                resumeOnce(with: .failure(ImageRecognitionError.requestFailed(error.localizedDescription)))
            }
        }
    }
}

extension BarcodeKind {
    var visionSymbology: VNBarcodeSymbology? {
        switch self {
        case .qr:
            return .qr
        case .ean13:
            return .ean13
        case .ean8:
            return .ean8
        case .upce:
            return .upce
        case .code128:
            return .code128
        case .code39:
            return .code39
        case .pdf417:
            return .pdf417
        case .aztec:
            return .aztec
        case .dataMatrix:
            return .dataMatrix
        }
    }

    /// 不支持的码制返回 nil；调用方决定是丢弃还是上报。
    init?(symbology: VNBarcodeSymbology) {
        switch symbology {
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
            return nil
        }
    }
}
