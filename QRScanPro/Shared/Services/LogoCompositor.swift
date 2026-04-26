import CoreGraphics
import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 在 QR 图像中央合成 Logo；带白色 padding 提升可读性。
enum LogoCompositor {
    static func composite(qrImage: CGImage, logoData: Data?, ratio: Double) -> CGImage {
        guard
            let data = logoData, !data.isEmpty,
            ratio > 0,
            let logo = decodeImage(data)
        else {
            return qrImage
        }

        let width = qrImage.width
        let height = qrImage.height
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return qrImage
        }

        ctx.draw(qrImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let side = CGFloat(min(width, height)) * CGFloat(min(max(ratio, 0), 0.5))
        let logoRect = CGRect(
            x: (CGFloat(width) - side) / 2,
            y: (CGFloat(height) - side) / 2,
            width: side,
            height: side
        )
        let pad = side * 0.1
        let backgroundRect = logoRect.insetBy(dx: -pad, dy: -pad)
        ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(backgroundRect)

        ctx.draw(logo, in: logoRect)

        return ctx.makeImage() ?? qrImage
    }

    private static func decodeImage(_ data: Data) -> CGImage? {
        #if os(iOS)
        return UIImage(data: data)?.cgImage
        #elseif os(macOS)
        guard let image = NSImage(data: data) else { return nil }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }
}
