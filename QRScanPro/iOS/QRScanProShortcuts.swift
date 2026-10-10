import AppIntents

/// App Shortcuts：安装后由系统自动索引到 Spotlight（桌面下拉搜索）/ Siri / 锁屏等入口。
///
/// **短语的源语言是英文**（与 target 的 development language 一致），中文译文放在
/// `iOS/zh-Hans.lproj/AppShortcuts.strings`。这样日语、法语等没有译文的环境会回退到
/// 英文短语；反过来把中文当源语言时，这些环境会回退成中文。
/// 短语里的 `\(.applicationName)` 在 strings 文件中写作 `${applicationName}`。
struct QRScanProShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenScannerIntent(),
            phrases: [
                "Scan with \(.applicationName)",
                "Scan a QR code with \(.applicationName)",
                "Scan qrcode with \(.applicationName)",
                "Open \(.applicationName) scanner"
            ],
            shortTitle: "扫一扫",
            systemImageName: "qrcode.viewfinder"
        )
        AppShortcut(
            intent: OpenGeneratorIntent(),
            phrases: [
                "Generate QR code with \(.applicationName)",
                "Generate a QR code with \(.applicationName)",
                "Open \(.applicationName) QR code generator"
            ],
            shortTitle: "生成二维码",
            systemImageName: "plus.viewfinder"
        )
    }
}
