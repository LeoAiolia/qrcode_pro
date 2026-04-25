import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var debugPresented = false
    private let capability = PlatformCapability()

    var body: some View {
        List {
            Section("码制配置") {
                ForEach(BarcodeKind.configurableKinds) { kind in
                    Toggle(kind.displayName, isOn: binding(for: kind))
                }
            }

            #if os(iOS)
            if capability.supportsCameraScanning {
                Section("扫描行为") {
                    Toggle("振动反馈", isOn: $store.settings.vibrationEnabled)
                    Toggle("音效反馈", isOn: $store.settings.soundEnabled)
                    Toggle("连续扫描", isOn: $store.settings.continuousScanEnabled)
                }
            }
            #endif

            Section("通用") {
                Picker("外观", selection: $store.settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }

                Picker("历史保留时长", selection: $store.settings.historyRetention) {
                    ForEach(HistoryRetention.allCases) { retention in
                        Text(retention.title).tag(retention)
                    }
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppTheme.textSecondary)
                }

                #if DEBUG
                Button {
                    debugPresented = true
                } label: {
                    Label("调试日志", systemImage: "ladybug")
                }
                #endif
            }
        }
        .hideScrollBackgroundWhenAvailable()
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("设置")
        .sheet(isPresented: $debugPresented) {
            NavigationView {
                DebugLogView()
            }
        }
    }

    private func binding(for kind: BarcodeKind) -> Binding<Bool> {
        Binding(
            get: {
                store.settings.enabledKinds.contains(kind)
            },
            set: { isEnabled in
                if isEnabled {
                    store.settings.enabledKinds.insert(kind)
                } else {
                    store.settings.enabledKinds.remove(kind)
                }
            }
        )
    }
}
