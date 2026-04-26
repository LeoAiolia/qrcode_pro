import AudioToolbox
import UIKit

/// 扫描成功反馈封装；振动 / 音效是否触发由 SettingsStore 控制。
enum HapticFeedback {
    /// 系统提示音 1057：单次“咔嗒”，与系统扫码常用音色一致。
    private static let scanSoundID: SystemSoundID = 1057

    static func scanSuccess(vibrate: Bool, sound: Bool) {
        if vibrate {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if sound {
            AudioServicesPlaySystemSound(scanSoundID)
        }
    }
}
