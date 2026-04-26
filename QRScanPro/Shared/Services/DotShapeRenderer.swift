import CoreGraphics
import Foundation

/// 把 QRCodeBitMatrix 按 GenerateConfig 指定的形状 / 配色 / 边距渲染为 CGImage。
enum DotShapeRenderer {
    static func render(matrix: QRCodeBitMatrix, config: GenerateConfig) -> CGImage? {
        let moduleCount = matrix.size
        guard moduleCount > 0 else { return nil }
        let totalModules = moduleCount + 2 * max(0, config.marginModules)
        let pixelSize = max(config.sizePx, totalModules * 2)
        let modulePx = CGFloat(pixelSize) / CGFloat(totalModules)

        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let bgColor = HexColor(hex: config.backgroundHex)?.cgColor ?? CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        ctx.setFillColor(bgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

        let fgColor = HexColor(hex: config.foregroundHex)?.cgColor ?? CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        ctx.setFillColor(fgColor)

        let margin = CGFloat(config.marginModules)

        for row in 0..<moduleCount {
            for col in 0..<moduleCount where matrix.modules[row][col] {
                let x = (CGFloat(col) + margin) * modulePx
                // CGContext 原点在左下角；matrix row=0 是顶部，需翻转。
                let y = (CGFloat(moduleCount - 1 - row) + margin) * modulePx
                let rect = CGRect(x: x, y: y, width: modulePx, height: modulePx)

                switch config.dotShape {
                case .square:
                    ctx.fill(rect)
                case .circle:
                    ctx.fillEllipse(in: rect)
                case .rounded:
                    let radius = modulePx * 0.3
                    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
                    ctx.addPath(path)
                    ctx.fillPath()
                }
            }
        }

        return ctx.makeImage()
    }
}
