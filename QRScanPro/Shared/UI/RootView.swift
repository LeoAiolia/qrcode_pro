import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab: AppTab = AppTab.availableTabs.first ?? .scanner
    @State private var generatorPresented = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.availableTabs, id: \.self) { tab in
                screen(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .accentColor(AppTheme.accent)
        .preferredColorScheme(colorScheme)
        #if os(iOS)
        .sheet(isPresented: $generatorPresented) {
            NavigationView {
                GeneratorView()
            }
        }
        #endif
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .scanner:
            NavigationView {
                ScannerView()
                    #if os(iOS)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                generatorPresented = true
                            } label: {
                                Label("生成", systemImage: "qrcode")
                            }
                        }
                    }
                    #endif
            }
        case .generator:
            NavigationView {
                GeneratorView()
            }
        case .history:
            NavigationView {
                HistoryView()
            }
        case .settings:
            NavigationView {
                SettingsView()
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch store.settings.appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
