import CoreGraphics
import Foundation
import Vision

enum ImageRecognitionError: LocalizedError {
    case noBarcode
    case noEnabledKind
    case invalidImage
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .noBarcode:
            return "未在图片中识别到二维码或条形码"
        case .noEnabledKind:
            return "请先在设置中启用至少一种码制"
        case .invalidImage:
            return "图片无法读取"
        case .requestFailed(let message):
            return "图片识别失败：\(message)"
        }
    }
}

struct BarcodeImageRecognizer {
    func recognize(cgImage: CGImage, allowedKinds: Set<BarcodeKind>) async throws -> ScanResult {
        let allowedSymbologies = allowedKinds.compactMap { kind in
            kind.visionSymbology
        }

        guard !allowedSymbologies.isEmpty else {
            throw ImageRecognitionError.noEnabledKind
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ScanResult, Error>) in
            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    continuation.resume(throwing: ImageRecognitionError.requestFailed(error.localizedDescription))
                    return
                }

                guard
                    let observations = request.results as? [VNBarcodeObservation],
                    let observation = observations.first,
                    let value = observation.payloadStringValue
                else {
                    continuation.resume(throwing: ImageRecognitionError.noBarcode)
                    return
                }

                let result = ScanResult(
                    value: value,
                    kind: BarcodeKind(symbology: observation.symbology),
                    source: .image
                )
                continuation.resume(returning: result)
            }
            request.symbologies = allowedSymbologies

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ImageRecognitionError.requestFailed(error.localizedDescription))
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
        case .unknown:
            return nil
        }
    }

    init(symbology: VNBarcodeSymbology) {
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
            self = .unknown
        }
    }
}
