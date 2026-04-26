import Foundation

/// 直接基于 BitMatrix 输出可缩放 SVG；默认使用方形模块（dotShape 信息暂不参与 SVG，保持矢量简洁）。
enum SVGExporter {
    static func string(matrix: QRCodeBitMatrix, config: GenerateConfig) -> String {
        let moduleCount = matrix.size
        let total = moduleCount + 2 * max(0, config.marginModules)
        let margin = config.marginModules

        var rects = ""
        rects.reserveCapacity(moduleCount * moduleCount * 30)

        for row in 0..<moduleCount {
            for col in 0..<moduleCount where matrix.modules[row][col] {
                let x = col + margin
                let y = row + margin
                rects.append("<rect x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>")
            }
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="\(config.sizePx)" height="\(config.sizePx)" viewBox="0 0 \(total) \(total)" shape-rendering="crispEdges">
        <rect width="\(total)" height="\(total)" fill="\(config.backgroundHex)"/>
        <g fill="\(config.foregroundHex)">\(rects)</g>
        </svg>
        """
    }

    static func data(matrix: QRCodeBitMatrix, config: GenerateConfig) -> Data {
        Data(string(matrix: matrix, config: config).utf8)
    }
}
