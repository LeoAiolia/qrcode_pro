import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

enum QRCodeGenerationError: LocalizedError {
    case emptyContent
    case filterFailed
    case imageRenderFailed

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "请输入需要生成二维码的内容"
        case .filterFailed:
            return "二维码生成器初始化失败"
        case .imageRenderFailed:
            return "二维码图片渲染失败"
        }
    }
}

struct QRCodeGenerator {
    private let context = CIContext()

    func generate(
        content: String,
        correctionLevel: QRErrorCorrectionLevel,
        size: CGFloat,
        foregroundColor: CIColor = CIColor(red: 0.07, green: 0.07, blue: 0.07),
        backgroundColor: CIColor = CIColor(red: 1, green: 1, blue: 1)
    ) throws -> PlatformImage {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw QRCodeGenerationError.emptyContent
        }

        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(trimmedContent.utf8)
        generator.correctionLevel = correctionLevel.rawValue

        guard let outputImage = generator.outputImage else {
            throw QRCodeGenerationError.filterFailed
        }

        let falseColor = CIFilter.falseColor()
        falseColor.inputImage = outputImage
        falseColor.color0 = foregroundColor
        falseColor.color1 = backgroundColor

        guard let coloredImage = falseColor.outputImage else {
            throw QRCodeGenerationError.filterFailed
        }

        let scale = size / coloredImage.extent.width
        let transformedImage = coloredImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            throw QRCodeGenerationError.imageRenderFailed
        }

        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        #endif
    }
}
