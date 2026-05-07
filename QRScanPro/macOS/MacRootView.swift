import SwiftData
import SwiftUI

struct MacRootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @State private var selection: SidebarItem? = .generator
    @State private var generatorState = GeneratorState()

    enum SidebarItem: Hashable, CaseIterable, Identifiable {
        case generator
        case imageRecognition
        case history
        case settings

        var id: Self { self }

        var title: String {
            switch self {
            case .imageRecognition:
                return "图片识别"
            case .generator:
                return "生成"
            case .history:
                return "生成历史"
            case .settings:
                return "设置"
            }
        }

        var systemImage: String {
            switch self {
            case .imageRecognition:
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
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(Optional(item))
            }
            .navigationTitle("QRScan Pro")
            .frame(minWidth: 180)
        } detail: {
            detail(for: selection ?? .imageRecognition)
        }
        .preferredColorScheme(colorScheme(for: settings.appearance))
        .task {
            let repo = SwiftDataHistoryRepository(context: modelContext)
            do {
                try repo.applyRetention(settings.historyRetention, now: Date())
            } catch {
                DebugLogger.shared.warning("启动清理失败：\(error.localizedDescription)")
            }
        }
    }

    @ViewBuilder
    private func detail(for item: SidebarItem) -> some View {
        switch item {
        case .generator:
            GeneratorView(persistedState: generatorState)
        case .imageRecognition:
            MacImageRecognitionView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
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
