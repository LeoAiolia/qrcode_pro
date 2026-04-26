import SwiftUI

/// 透明像素预览常用棋盘格底；8 px 单元，浅 / 深色自适应。
struct CheckerboardBackground: View {
    private let unit: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / unit))
            let rows = Int(ceil(size.height / unit))
            let dark = AppColor.surfaceRaised
            let light = AppColor.surface

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(light)
            )

            for row in 0..<rows {
                for col in 0..<cols where (row + col).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: CGFloat(col) * unit,
                        y: CGFloat(row) * unit,
                        width: unit,
                        height: unit
                    )
                    context.fill(Path(rect), with: .color(dark))
                }
            }
        }
    }
}
