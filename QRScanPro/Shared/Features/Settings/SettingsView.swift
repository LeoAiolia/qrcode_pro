import SwiftUI

#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var debugPresented = false
    private let capability = PlatformCapability()

    var body: some View {
        @Bindable var settings = settings

        return List {
            #if os(iOS)
            Section("码制配置") {
                ForEach(BarcodeKind.allCases) { kind in
                    Toggle(kind.displayName, isOn: binding(for: kind, on: settings))
                }
            }

            if capability.supportsCameraScanning {
                Section("扫描行为") {
                    Toggle("振动反馈", isOn: $settings.vibrationEnabled)
                    Toggle("音效反馈", isOn: $settings.soundEnabled)
                    Toggle("连续扫描", isOn: $settings.continuousScanEnabled)
                    Picker("扫描框", selection: $settings.scanFrameStyle) {
                        ForEach(ScanFrameStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                }
            }
            #else
            Section("识别 / 生成码制") {
                ForEach(BarcodeKind.allCases) { kind in
                    Toggle(kind.displayName, isOn: binding(for: kind, on: settings))
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
            }

            #if os(macOS)
            Section("导出") {
                Picker("默认导出格式", selection: $settings.defaultExportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }

                exportDirectoryRow(settings: settings)
            }
            #endif

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

    #if os(macOS)
    @ViewBuilder
    private func exportDirectoryRow(settings: SettingsStore) -> some View {
        let resolvedURL = settings.defaultExportDirectoryBookmark.flatMap(ExportDirectoryBookmark.resolve)

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("默认导出目录")
                Text(resolvedURL?.path ?? "每次询问")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("选择…") {
                pickDirectory(settings: settings)
            }

            if settings.defaultExportDirectoryBookmark != nil {
                Button(role: .destructive) {
                    settings.defaultExportDirectoryBookmark = nil
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func pickDirectory(settings: SettingsStore) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let bookmark = ExportDirectoryBookmark.encode(url) {
            settings.defaultExportDirectoryBookmark = bookmark
        }
    }
    #endif
}
