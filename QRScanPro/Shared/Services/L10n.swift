import Foundation

/// 轻量本地化访问层：为「App 内切换语言」提供非视图路径（LocalizedError / CSV / 日志等）的文案解析。
///
/// 视图内的字符串字面量（`Text("…")`、`Label("…")` 等）走 SwiftUI 的 `LocalizedStringKey`，
/// 随根节点注入的 `.environment(\.locale, …)` 即时翻转，不经由本层。
enum L10n {
    /// 当前 App 语言对应的系统 Locale（跟随系统 → 自动更新）。
    static var resolvedLocale: Locale {
        guard let identifier = currentLanguage.identifier else { return .autoupdatingCurrent }
        return Locale(identifier: identifier)
    }

    /// 视图外的运行时文案翻译。
    /// - 显式英文：查 `en.lproj`
    /// - 跟随系统：查 `.main`（随系统语言）
    /// - 显式中文：直接返回 key（源串即中文，无需查表，因源语言不会生成 `zh-Hans.lproj`）
    static func t(_ key: String) -> String {
        switch currentLanguage {
        case .english:
            guard let bundle = enBundle else { return key }
            return bundle.localizedString(forKey: key, value: key, table: "Localizable")
        case .system:
            return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
        case .zhHans:
            return key
        }
    }

    // MARK: - 当前语言

    private static var currentLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "app.language") ?? AppLanguage.system.rawValue) ?? .system
    }

    private static var enBundle: Bundle? {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }
}
