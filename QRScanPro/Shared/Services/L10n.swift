import Foundation

/// 轻量本地化访问层：为「App 内切换语言」提供非视图路径（LocalizedError / CSV / 日志等）的文案解析。
///
/// 视图内的字符串字面量（`Text("…")`、`Label("…")` 等）走 SwiftUI 的 `LocalizedStringKey`，
/// 随根节点注入的 `.environment(\.locale, …)` 即时翻转，不经由本层。
enum L10n {
    /// 当前 App 语言对应的 SwiftUI 环境 Locale（跟随系统 → 按设备系统语言解析）。
    static var resolvedLocale: Locale {
        if let identifier = currentLanguage.identifier {
            return Locale(identifier: identifier)
        }
        let resolved = AppLanguage.resolvedSystemLanguage
        return Locale(identifier: resolved.identifier ?? "en")
    }

    /// 视图外的运行时文案翻译。
    /// - 解析为英文：查 `en.lproj`
    /// - 解析为中文：直接返回 key（源串即中文，无需查表，因源语言不会生成 `zh-Hans.lproj`）
    ///
    /// 注意「跟随系统」不走 `Bundle.main.localizedString`：进程首选本地化在启动时从
    /// `AppleLanguages` 读入并缓存，运行中从显式语言切回「跟随系统」后缓存仍是旧语言，
    /// 会残留上一次显式选择（如 en → system 仍显示英文）。改用系统区域实时判定。
    static func t(_ key: String) -> String {
        switch resolvedLanguage {
        case .english:
            guard let bundle = enBundle else { return key }
            return bundle.localizedString(forKey: key, value: key, table: "Localizable")
        case .zhHans, .system:
            return key
        }
    }

    private static var enBundle: Bundle? {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    // MARK: - 当前语言

    private static var currentLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "app.language") ?? AppLanguage.system.rawValue) ?? .system
    }

    /// 实际渲染语言：显式选择优先；「跟随系统」按系统区域语言实时解析。
    private static var resolvedLanguage: AppLanguage {
        switch currentLanguage {
        case .system:
            return AppLanguage.resolvedSystemLanguage
        case .zhHans, .english:
            return currentLanguage
        }
    }

    // MARK: - 系统控件语言覆盖

    /// 让系统控件（取色器「网络 / 光栅 / 滑块」、相册选择器、分享面板等）即时跟随 App 语言。
    ///
    /// 双保险：
    /// 1. `LanguageBundle` swizzle——把 `Bundle.main` 的本地化查找重定向到目标语言，
    ///    即时生效（AppleLanguages 只能下次启动生效，且对 UIKit 弹层不一定够）。
    /// 2. `AppleLanguages`——覆盖进程首选本地化，兜底 swizzle 覆盖不到的路径（如权限弹窗）。
    /// - 跟随系统：取消重定向 + 清除 AppleLanguages，恢复系统语言。
    static func syncPreferredLocalization(_ language: AppLanguage) {
        guard let identifier = language.identifier else {
            LanguageBundle.apply(languageIdentifier: nil)
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            return
        }
        LanguageBundle.apply(languageIdentifier: identifier)

        let defaults = UserDefaults.standard
        if defaults.stringArray(forKey: "AppleLanguages") != [identifier] {
            defaults.set([identifier], forKey: "AppleLanguages")
        }
    }

    /// 启动早期调用：安装 swizzle 并按当前语言设置一次（兜底异常退出导致的偏差）。
    static func syncPreferredLocalizationAtLaunch() {
        LanguageBundle.install()
        syncPreferredLocalization(currentLanguage)
    }

    /// 当前是否渲染为英文（「跟随系统」按系统区域实时判定，不读进程首选本地化缓存）。
    static var isEnglish: Bool {
        resolvedLanguage == .english
    }
}
