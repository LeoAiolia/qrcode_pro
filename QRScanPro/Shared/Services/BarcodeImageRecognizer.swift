import CoreGraphics
import Foundation
import Vision

enum ImageRecognitionError: LocalizedError {
    case noBarcode
    case invalidImage
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .noBarcode:
            return "未在图片中识别到二维码或条形码"
        case .invalidImage:
            return "图片无法读取"
        case .requestFailed(let message):
            return "图片识别失败：\(message)"
        }
    }
}

struct BarcodeImageRecognizer {
    func recognize(cgImage: CGImage) async throws -> ScanResult {
        try await withCheckedThrowingContinuation { continuation in
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
