import Foundation
import ObjectiveC

/// `Bundle` 子类：把「主 Bundle 的本地化查找」重定向到指定语言的 lproj 子 Bundle。
///
/// 用途：系统控件（取色器「网络 / 光栅 / 滑块」、相册选择器、权限弹窗等）的文案
/// 经由 `Bundle.main.localizedString` 解析，默认跟随系统语言。`AppleLanguages` 只能
/// 在重启后改变进程首选本地化，无法即时切换；本类通过 method swizzle 把
/// `Bundle.main` 的查找结果转发给目标语言子 Bundle，实现即时翻转。
final class LanguageBundle: Bundle, @unchecked Sendable {
    /// 目标语言 lproj 子 Bundle；nil 时透传原实现（跟随系统）。
    nonisolated(unsafe) private static var overridden: Bundle?
    /// 是否已安装 swizzle。
    nonisolated(unsafe) private static var installed = false

    /// 安装 swizzle（幂等，重复调用无副作用）。必须在 App 启动时调用一次。
    static func install() {
        guard !installed else { return }
        let original = #selector(Bundle.localizedString(forKey:value:table:))
        let swizzled = #selector(LanguageBundle.swizzledLocalizedString(forKey:value:table:))
        guard
            let originalMethod = class_getInstanceMethod(Bundle.self, original),
            let swizzledMethod = class_getInstanceMethod(Bundle.self, swizzled)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
        installed = true
    }

    /// swizzled 后所有 Bundle 实例都会进入本方法；仅重定向 `Bundle.main` 的查找，
    /// 框架自身 Bundle（UIKitCore 内部资源）保持原样，避免整个进程系统文案被改写。
    @objc private func swizzledLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let target = Self.overridden, self === Bundle.main {
            return target.localizedString(forKey: key, value: value, table: tableName)
        }
        // 交换实现后，这个调用在运行期指向原生实现。
        return swizzledLocalizedString(forKey: key, value: value, table: tableName)
    }

    /// 更新重定向目标；identifier 为 nil 时取消重定向（跟随系统）。
    static func apply(languageIdentifier: String?) {
        guard
            let identifier = languageIdentifier,
            let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
            // 创建失败极罕见；失败则退回 nil 透传，宁缺勿错。
            let bundle = Bundle(path: path)
        else {
            overridden = nil
            return
        }
        overridden = bundle
    }
}
