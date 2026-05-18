import SwiftData
import SwiftUI

@main
struct QRScanProApp: App {
    @State private var settings = SettingsStore()
    @State private var splashVisible = true
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: ScanRecord.self, GeneratedRecord.self)
        } catch {
            fatalError("SwiftData ModelContainer 初始化失败：\(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                iOSRootView()
                    .environment(settings)
                if splashVisible {
                    SplashView(isVisible: $splashVisible)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.35), value: splashVisible)
        }
        .modelContainer(container)
    }
}
