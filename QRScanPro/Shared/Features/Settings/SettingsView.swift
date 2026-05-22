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
            Section("码制") {
                ForEach(BarcodeKind.allCases) { kind in
                    Toggle(isOn: binding(for: kind, on: settings)) {
                        Label {
                            Text(kind.displayName)
                        } icon: {
                            SettingIcon(systemName: kind.settingsIcon, tint: kind.settingsTint)
                        }
                    }
                }
            }

            if capability.supportsCameraScanning {
                Section("扫描") {
                    Toggle(isOn: $settings.vibrationEnabled) {
                        Label {
                            Text("振动反馈")
                        } icon: {
                            SettingIcon(systemName: "iphone.radiowaves.left.and.right", tint: .green)
                        }
                    }
                    Toggle(isOn: $settings.soundEnabled) {
                        Label {
                            Text("音效反馈")
                        } icon: {
                            SettingIcon(systemName: "speaker.wave.2.fill", tint: .purple)
                        }
                    }
                    Toggle(isOn: $settings.continuousScanEnabled) {
                        Label {
                            Text("连续扫描")
                        } icon: {
                            SettingIcon(systemName: "infinity", tint: .orange)
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
                Picker(selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                } label: {
                    Label {
                        Text("外观")
                    } icon: {
                        SettingIcon(systemName: "circle.lefthalf.filled", tint: .blue)
                    }
                }

                Picker(selection: $settings.historyRetention) {
                    ForEach(HistoryRetention.allCases) { retention in
                        Text(retention.title).tag(retention)
                    }
                } label: {
                    Label {
                        Text("历史保留时长")
                    } icon: {
                        SettingIcon(systemName: "clock.fill", tint: .orange)
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
                    Label {
                        Text("版本")
                    } icon: {
                        SettingIcon(systemName: "info.circle.fill", tint: .blue)
                    }
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundColor(AppColor.textSecondary)
                        .font(.system(.body, design: .monospaced))
                }

                #if DEBUG
                Button {
                    debugPresented = true
                } label: {
                    Label {
                        Text("调试日志")
                    } icon: {
                        SettingIcon(systemName: "ladybug.fill", tint: .red)
                    }
                }
                #endif
            }
        }
        #if os(macOS)
        .labelStyle(SettingLabelStyle())
        #endif
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

// MARK: - Setting Icon

private struct SettingIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: Self.iconFontSize, weight: .medium))
            .foregroundColor(.white)
            .frame(width: Self.size, height: Self.size)
            .background(tint, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    #if os(macOS)
    private static let size: CGFloat = 20
    private static let iconFontSize: CGFloat = 11
    private static let cornerRadius: CGFloat = 5
    #else
    private static let size: CGFloat = 28
    private static let iconFontSize: CGFloat = 13
    private static let cornerRadius: CGFloat = 6
    #endif
}

#if os(macOS)
/// macOS 上 Label 默认图标-标题间距过小，统一用此样式显式补间距。
private struct SettingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}
#endif

// MARK: - BarcodeKind + Settings icon

private extension BarcodeKind {
    var settingsIcon: String {
        switch self {
        case .qr:
            return "qrcode"
        case .pdf417, .aztec, .dataMatrix:
            return "qrcode"
        case .ean13, .ean8, .upce, .code128, .code39:
            return "barcode"
        }
    }

    var settingsTint: Color {
        switch self {
        case .qr:
            return .blue
        case .pdf417:
            return .purple
        case .aztec:
            return .indigo
        case .dataMatrix:
            return Color(red: 0.2, green: 0.5, blue: 0.8)
        case .ean13, .ean8:
            return .green
        case .upce, .code128, .code39:
            return Color(red: 0.3, green: 0.6, blue: 0.3)
        }
    }
}
