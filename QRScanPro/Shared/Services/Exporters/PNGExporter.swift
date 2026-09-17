import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PNGExporter {
    /// 生成历史缩略图的目标边长（px）；列表展示足够，避免入库全尺寸位图。
    static let thumbnailSizePx = 120

    static func data(from cgImage: CGImage) -> Data? {
        let mutData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutData as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return mutData as Data
    }

    /// 先按 `maxSizePx` 等比降采样再编码 PNG；解码失败时返回 nil，由调用方决定兜底。
    static func thumbnailData(from cgImage: CGImage, maxSizePx: Int = PNGExporter.thumbnailSizePx) -> Data? {
        let maxSide = max(cgImage.width, cgImage.height)
        guard maxSide > maxSizePx else {
            return data(from: cgImage)
        }
        let scale = CGFloat(maxSizePx) / CGFloat(maxSide)
        let targetWidth = max(1, Int((CGFloat(cgImage.width) * scale).rounded()))
        let targetHeight = max(1, Int((CGFloat(cgImage.height) * scale).rounded()))

        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        guard let scaled = ctx.makeImage() else {
            return nil
        }
        return data(from: scaled)
    }
}
