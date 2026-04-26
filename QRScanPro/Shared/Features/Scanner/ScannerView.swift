import SwiftUI

/// M1 占位实现；M2 将重写为全屏取景 / 闪光灯 / 扫描框 + macOS 拖拽多选。
struct ScannerView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "qrcode.viewfinder",
            title: "扫码",
            subtitle: "M2 将上线全屏取景、闪光灯、连续扫描与 macOS 拖拽识别。"
        )
        #if os(iOS)
        .navigationTitle("扫码")
        #else
        .navigationTitle("图片识别")
        #endif
    }
}
