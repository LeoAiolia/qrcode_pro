import SwiftUI

#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    /// 声明 locale 依赖：body 内的 `L10n.t("每次询问")` 随语言切换即时刷新。
    @Environment(\.locale) private var locale
    @State private var debugPresented = false
    @State private var privacyPolicyPresented = false
    private let capability = PlatformCapability()

    /// 控制“调试日志”入口是否显示；默认不显示，需要调试时改为 true（仅 Debug 构建生效）。
    private static let showsDebugLogEntry = false

    /// 隐私政策地址：跟随 App 实际渲染语言选中文 / 英文版页面（英文版部署在 /en/ 子路径）。
    /// 经由 L10n 判定，与界面文案保持同源，「跟随系统」时不残留旧选择。
    private var privacyPolicyURL: URL? {
        L10n.isEnglish
            ? URL(string: "https://leoaiolia.github.io/qrcode_pro/en/privacy-policy.html")
            : URL(string: "https://leoaiolia.github.io/qrcode_pro/privacy-policy.html")
    }

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
                Picker(selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        // 选项名固定不翻译：各语言以自身名字呈现（简体中文 / English），
                        // 仅「跟随系统」跟随界面语言本地化。
                        if language == .system {
                            Text(LocalizedStringKey(language.title)).tag(language)
                        } else {
                            Text(language.title).tag(language)
                        }
                    }
                } label: {
                    Label {
                        Text("语言")
                    } icon: {
                        SettingIcon(systemName: "globe", tint: .blue)
                    }
                }
                // 系统控件（取色器 / 权限弹窗等）文案要重启才切换，App 界面即时切换。
                if settings.language != .system {
                    Text("系统弹窗语言将在重启 App 后生效")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.textSecondary)
                }

                Picker(selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(LocalizedStringKey(appearance.title)).tag(appearance)
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
                        Text(LocalizedStringKey(retention.title)).tag(retention)
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

                Button {
                    openPrivacyPolicy()
                } label: {
                    HStack {
                        Label {
                            Text("隐私政策")
                        } icon: {
                            SettingIcon(systemName: "hand.raised.fill", tint: .purple)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .settingsRowActionStyle()

                #if DEBUG
                if Self.showsDebugLogEntry {
                    Button {
                        debugPresented = true
                    } label: {
                        HStack {
                            Label {
                                Text("调试日志")
                            } icon: {
                                SettingIcon(systemName: "ladybug.fill", tint: .red)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .settingsRowActionStyle()
                }
                #endif
            }
        }
        #if os(macOS)
        .labelStyle(SettingLabelStyle())
        #endif
        .hideScrollBackgroundWhenAvailable()
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(L10n.t("设置"))
        .sheet(isPresented: $debugPresented) {
            NavigationStack {
                DebugLogView()
            }
        }
        #if os(iOS)
        .sheet(isPresented: $privacyPolicyPresented) {
            if let url = privacyPolicyURL {
                InAppBrowserView(url: url)
            }
        }
        #endif
    }

    private func openPrivacyPolicy() {
        #if os(iOS)
        privacyPolicyPresented = true
        #else
        if let url = privacyPolicyURL {
            NSWorkspace.shared.open(url)
        }
        #endif
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
                Text(resolvedURL?.path ?? L10n.t("每次询问"))
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
        panel.prompt = L10n.t("选择")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let bookmark = ExportDirectoryBookmark.encode(url) {
            settings.defaultExportDirectoryBookmark = bookmark
        }
    }
    #endif
}

// MARK: - Setting Icon

private extension View {
    /// macOS List 中 Button 默认样式带 NSButton 内边距，会使行首图标右偏；
    /// 改用 plain 样式与普通行对齐。iOS 保持系统默认按钮外观。
    @ViewBuilder
    func settingsRowActionStyle() -> some View {
        #if os(macOS)
        self.buttonStyle(.plain)
            .foregroundStyle(AppColor.textPrimary)
        #else
        self
        #endif
    }
}

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
