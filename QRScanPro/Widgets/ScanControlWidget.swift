import SwiftUI
import WidgetKit

/// 控制中心的「扫一扫」控件：点击拉起主 App 并跳到扫码页。
/// ControlWidget 仅 iOS 18+ 可用，本扩展部署目标即 18.0。
struct ScanControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.pz.qrscanpro.ScanControlWidget") {
            ControlWidgetButton(action: OpenScannerIntent()) {
                Label("扫一扫", systemImage: "qrcode.viewfinder")
            }
        }
    }
}
