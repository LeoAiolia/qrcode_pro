import SwiftData
import SwiftUI

@main
struct QRScanProApp: App {
    @State private var settings = SettingsStore()
    @State private var splashVisible = true
    private let container: ModelContainer
    private let historyRepository: SwiftDataHistoryRepository

    init() {
        do {
            let container = try ModelContainer(for: ScanRecord.self, GeneratedRecord.self)
            self.container = container
            self.historyRepository = SwiftDataHistoryRepository(context: container.mainContext)
        } catch {
            fatalError("SwiftData ModelContainer 初始化失败：\(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                iOSRootView()
                    .environment(settings)
                    .environment(historyRepository)
                if splashVisible {
                    SplashView(isVisible: $splashVisible)
                        .transition(.opacity)
                }
            }
            // 挂在 ZStack 上：SplashView 与 iOSRootView 都在 locale 环境作用域内
            .environment(\.locale, settings.resolvedLocale)
            .animation(.easeOut(duration: 0.35), value: splashVisible)
        }
        .modelContainer(container)
    }
}
