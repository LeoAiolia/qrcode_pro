import AppIntents

/// App Shortcuts：安装后由系统自动索引到 Spotlight（桌面下拉搜索）/ Siri / 锁屏等入口。
/// 短语的本地化见 iOS/en.lproj 与 iOS/zh-Hans.lproj 下的 AppShortcuts.strings。
struct QRScanProShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenScannerIntent(),
            phrases: [
                "\(.applicationName)扫一扫",
                "\(.applicationName)扫码",
                "用\(.applicationName)扫码",
                "用\(.applicationName)扫描二维码",
                "打开\(.applicationName)扫一扫",
                // 英文短语承载 qrcode 原词，让英文/缩写搜索（qr、qrcode）也能命中
                "Scan qrcode with \(.applicationName)"
            ],
            shortTitle: "扫一扫",
            systemImageName: "qrcode.viewfinder"
        )
        AppShortcut(
            intent: OpenGeneratorIntent(),
            phrases: [
                "\(.applicationName)生成二维码",
                "用\(.applicationName)生成二维码",
                "打开\(.applicationName)生成二维码",
                "Generate qrcode with \(.applicationName)"
            ],
            shortTitle: "生成二维码",
            systemImageName: "plus.viewfinder"
        )
    }
}
