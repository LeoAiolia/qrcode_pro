import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var debugPresented = false
    private let capability = PlatformCapability()

    var body: some View {
        @Bindable var settings = settings

        return List {
            Section("码制配置") {
                ForEach(BarcodeKind.allCases) { kind in
                    Toggle(kind.displayName, isOn: binding(for: kind, on: settings))
                }
            }

            #if os(iOS)
            if capability.supportsCameraScanning {
                Section("扫描行为") {
                    Toggle("振动反馈", isOn: $settings.vibrationEnabled)
                    Toggle("音效反馈", isOn: $settings.soundEnabled)
                    Toggle("连续扫描", isOn: $settings.continuousScanEnabled)
                }
            }
            #endif

            Section("通用") {
                Picker("外观", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }

                Picker("历史保留时长", selection: $settings.historyRetention) {
                    ForEach(HistoryRetention.allCases) { retention in
                        Text(retention.title).tag(retention)
                    }
                }

                #if os(macOS)
                Picker("默认导出格式", selection: $settings.defaultExportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                #endif
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppColor.textSecondary)
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
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("设置")
        .sheet(isPresented: $debugPresented) {
            NavigationStack {
                DebugLogView()
            }
        }
    }

    private func binding(for kind: BarcodeKind, on settings: SettingsStore) -> Binding<Bool> {
        Binding(
            get: { settings.enabledKinds.contains(kind) },
            set: { isEnabled in
                if isEnabled {
                    settings.enabledKinds.insert(kind)
                } else {
                    settings.enabledKinds.remove(kind)
                }
            }
        )
    }
}
