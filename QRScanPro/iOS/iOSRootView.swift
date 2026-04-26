import SwiftData
import SwiftUI

struct iOSRootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .scanner

    enum Tab: Hashable {
        case scanner
        case generator
        case history
        case settings

        var title: String {
            switch self {
            case .scanner:
                return "扫码"
            case .generator:
                return "生成"
            case .history:
                return "历史"
            case .settings:
                return "设置"
            }
        }

        var systemImage: String {
            switch self {
            case .scanner:
                return "qrcode.viewfinder"
            case .generator:
                return "qrcode"
            case .history:
                return "clock"
            case .settings:
                return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScannerView()
            }
            .tabItem {
                Label(Tab.scanner.title, systemImage: Tab.scanner.systemImage)
            }
            .tag(Tab.scanner)

            NavigationStack {
                GeneratorView()
            }
            .tabItem {
                Label(Tab.generator.title, systemImage: Tab.generator.systemImage)
            }
            .tag(Tab.generator)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(Tab.history.title, systemImage: Tab.history.systemImage)
            }
            .tag(Tab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
            }
            .tag(Tab.settings)
        }
        .tint(AppColor.accent)
        .preferredColorScheme(colorScheme(for: settings.appearance))
        .task {
            QRCodeGeneratorWarmup.start()

            let repo = SwiftDataHistoryRepository(context: modelContext)
            do {
                try repo.applyRetention(settings.historyRetention, now: Date())
            } catch {
                DebugLogger.shared.warning("启动清理失败：\(error.localizedDescription)")
            }
        }
    }

    private func colorScheme(for appearance: AppAppearance) -> ColorScheme? {
        switch appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
