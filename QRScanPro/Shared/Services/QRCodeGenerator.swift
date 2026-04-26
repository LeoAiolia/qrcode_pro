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

/// QR 模块矩阵：modules[row][col] == true 表示该模块需绘制（黑点）。
/// 行优先，row=0 是顶部；包含 CIFilter 默认输出的内置 quiet zone。
struct QRCodeBitMatrix: Equatable {
    let modules: [[Bool]]
    var size: Int { modules.count }
}

struct QRCodeGenerator {
    private let context = CIContext()

    /// 把内容编码为 QR，并把 CIFilter 的位图输出转成 BitMatrix。
    func bitMatrix(content: String, correctionLevel: QRErrorCorrectionLevel) throws -> QRCodeBitMatrix {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QRCodeGenerationError.emptyContent
        }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(trimmed.utf8)
        filter.correctionLevel = correctionLevel.rawValue

        guard let ciImage = filter.outputImage else {
            throw QRCodeGenerationError.filterFailed
        }
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw QRCodeGenerationError.imageRenderFailed
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            throw QRCodeGenerationError.imageRenderFailed
        }

        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let bitmapCtx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw QRCodeGenerationError.imageRenderFailed
        }

        // 翻转 y 轴：CIImage 默认 y 向上，绘制后我们按 row=0 取顶部行。
        bitmapCtx.translateBy(x: 0, y: CGFloat(height))
        bitmapCtx.scaleBy(x: 1, y: -1)
        bitmapCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var matrix = Array(repeating: Array(repeating: false, count: width), count: height)
        for y in 0..<height {
            let rowStart = y * bytesPerRow
            for x in 0..<width {
                let i = rowStart + x * 4
                let r = Int(pixels[i])
                let g = Int(pixels[i + 1])
                let b = Int(pixels[i + 2])
                // CIFilter 输出黑色模块 + 白色背景；阈值 384 = 128 * 3。
                matrix[y][x] = (r + g + b) < 384
            }
        }

        return QRCodeBitMatrix(modules: matrix)
    }

    /// 后台友好的生成管线：bitMatrix → DotShape → Logo 合成，输出 CGImage。
    /// 失败抛出 QRCodeGenerationError，调用方负责展示。
    func renderCGImage(content: String, config: GenerateConfig) throws -> (matrix: QRCodeBitMatrix, cgImage: CGImage) {
        let matrix = try bitMatrix(content: content, correctionLevel: config.correctionLevel)
        guard let baseImage = DotShapeRenderer.render(matrix: matrix, config: config) else {
            throw QRCodeGenerationError.imageRenderFailed
        }
        let composed = LogoCompositor.composite(qrImage: baseImage, logoData: config.logoData, ratio: config.logoRatio)
        return (matrix, composed)
    }

    /// 完整生成管线：bitMatrix → DotShape → Logo 合成 → PlatformImage。
    /// 失败抛出 QRCodeGenerationError，调用方负责展示。
    func render(content: String, config: GenerateConfig) throws -> (image: PlatformImage, matrix: QRCodeBitMatrix, cgImage: CGImage) {
        let result = try renderCGImage(content: content, config: config)
        let composed = result.cgImage
        return (PlatformImage.from(cgImage: composed), result.matrix, composed)
    }
}

extension PlatformImage {
    static func from(cgImage: CGImage) -> PlatformImage {
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}

enum QRCodeGeneratorWarmup {
    @MainActor private static var didStart = false

    @MainActor
    static func start() {
        guard !didStart else { return }
        didStart = true

        Task.detached(priority: .utility) {
            var config = GenerateConfig.default
            config.sizePx = 256
            _ = try? QRCodeGenerator().renderCGImage(content: "https://www.apple.com", config: config)
        }
    }
}
