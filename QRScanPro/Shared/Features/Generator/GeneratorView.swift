import SwiftUI

/// M1 占位实现；M3 将重写为完整生成器（颜色 / Logo / 形状 / 多格式导出 + 防抖预览）。
struct GeneratorView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "qrcode",
            title: "生成",
            subtitle: "M3 将上线颜色、Logo、形状参数与 PNG / SVG / PDF 导出。"
        )
        .navigationTitle("生成二维码")
    }
}
