import SwiftData
import SwiftUI

@main
struct QRScanProMacApp: App {
    @State private var settings = SettingsStore()
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: ScanRecord.self, GeneratedRecord.self)
        } catch {
            fatalError("SwiftData ModelContainer 初始化失败：\(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environment(settings)
                .frame(minWidth: 860, minHeight: 620)
        }
        .modelContainer(container)
    }
}
