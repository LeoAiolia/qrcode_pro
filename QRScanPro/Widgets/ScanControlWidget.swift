import SwiftUI
import WidgetKit

/// 控制中心的「扫一扫」控件：点击拉起主 App 并跳到扫码页。
/// ControlWidget 仅 iOS 18+ 可用，本扩展部署目标即 18.0。
/// 图标由 Label(systemImage:) 携带；displayName 提供画廊里的控件名，
/// 不设置时画廊会退化显示扩展名「QRScan Pro」。
struct ScanControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.pz.qrscanpro.ScanControlWidget") {
            ControlWidgetButton(action: OpenScannerIntent()) {
                Label("扫一扫", systemImage: "qrcode.viewfinder")
            }
        }
        .displayName("扫一扫")
    }
}
