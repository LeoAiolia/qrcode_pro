import SwiftData
import SwiftUI

@main
struct QRScanProMacApp: App {
    @State private var settings = SettingsStore()
    private let container: ModelContainer
    private let historyRepository: SwiftDataHistoryRepository

    init() {
        // 启动早期同步系统控件语言（保存面板 / 打开面板等跟随 App 语言）。
        L10n.syncPreferredLocalizationAtLaunch()

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
            MacRootView()
                .environment(settings)
                .environment(historyRepository)
                .frame(minWidth: 860, minHeight: 620)
                .environment(\.locale, settings.resolvedLocale)
        }
        .modelContainer(container)
    }
}
