import AppIntents
import Observation

/// App Intent 可跳转的目标页面。
enum AppRouteDestination: String, Equatable, Sendable {
    case scanner
    case generator
}

/// App Intent 与根视图之间传递跳转意图的轻量路由。
///
/// `openAppWhenRun = true` 时 intent 在主 App 进程内执行；冷启动场景下执行时机
/// 可能早于首帧 UI，因此先记录 pendingDestination，由 iOSRootView 在启动和变化时消费。
/// Widgets 扩展也会编译本文件（控制按钮引用 intent），路由仅在主 App 进程内生效。
@MainActor
@Observable
final class AppRoute {
    static let shared = AppRoute()

    private(set) var pendingDestination: AppRouteDestination?

    private init() {}

    func request(_ destination: AppRouteDestination) {
        pendingDestination = destination
    }

    /// 取出并清空待跳转目标；无待处理请求时返回 nil。
    func consumePending() -> AppRouteDestination? {
        let destination = pendingDestination
        pendingDestination = nil
        return destination
    }
}

/// 从控制中心 / Siri / Spotlight 拉起 App 并打开扫码页。
struct OpenScannerIntent: AppIntent {
    static let title: LocalizedStringResource = "打开扫一扫"
    static let description = IntentDescription("打开 QRScan Pro 开始扫码")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRoute.shared.request(.scanner)
        return .result()
    }
}

/// 从控制中心 / Siri / Spotlight 拉起 App 并打开生成二维码页。
struct OpenGeneratorIntent: AppIntent {
    static let title: LocalizedStringResource = "打开生成二维码"
    static let description = IntentDescription("打开 QRScan Pro 生成二维码")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRoute.shared.request(.generator)
        return .result()
    }
}
