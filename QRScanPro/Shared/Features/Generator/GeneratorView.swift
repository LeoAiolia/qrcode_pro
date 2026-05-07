import SwiftData
import SwiftUI

#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct GeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsStore.self) private var settings

    @State private var state: GeneratorState
    @State private var statusMessage: String?
    @State private var statusError: Bool = false
    #if os(iOS)
    @State private var advancedControlsReady: Bool
    @State private var didStartInitialGeneration = false
    #endif
    private let hidesTabBar: Bool
    #if os(iOS)
    @State private var logoPickerItem: PhotosPickerItem?
    #endif

    init(initialContent: String? = nil, initialConfig: GenerateConfig? = nil, hidesTabBar: Bool = false) {
        self.hidesTabBar = hidesTabBar
        _state = State(initialValue: GeneratorState(initialContent: initialContent, initialConfig: initialConfig))
        #if os(iOS)
        _advancedControlsReady = State(initialValue: hidesTabBar)
        #endif
    }

    var body: some View {
        Group {
            #if os(macOS)
            HSplitView {
                paramsForm
                    .frame(minWidth: 320, idealWidth: 360)
                previewPane
                    .frame(minWidth: 360)
            }
            #else
            ScrollView {
                VStack(spacing: Spacing.l) {
                    previewPane
                    paramsForm
                }
                .padding(Spacing.l)
            }
            .background(AppColor.background.ignoresSafeArea())
            #endif
        }
        .navigationTitle("生成二维码")
        #if os(iOS)
        .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
        #endif
        .task { await startInitialGeneration() }
        .onChange(of: state.content) { _, _ in state.scheduleRegenerate() }
        .onChange(of: state.config) { _, _ in state.scheduleRegenerate() }
        .overlay(alignment: .top) { statusBanner }
        #if os(iOS)
        .onChange(of: logoPickerItem) { _, item in
            Task { await loadPickedLogo(item: item) }
        }
        #endif
    }

    // MARK: - Preview

    private var previewPane: some View {
        VStack(spacing: Spacing.m) {
            ZStack {
                CheckerboardBackground()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.l))

                if let image = state.image {
                    PlatformImageView(image: image)
                        .padding(Spacing.l)
                } else if state.isGenerating {
                    ProgressView()
                } else if let error = state.error {
                    Text(error)
                        .font(AppFont.footnote)
                        .foregroundColor(AppColor.warning)
                        .padding()
                } else {
                    let emptyHint: String = {
                        #if os(macOS)
                        return "请在左侧输入内容"
                        #else
                        return "请在下方输入内容"
                        #endif
                    }()
                    Text(state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? emptyHint
                         : "等待生成…")
                        .font(AppFont.footnote)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .aspectRatio(1, contentMode: .fit)

            warnings
            #if os(macOS)
            saveToHistoryButton
            #endif
            exportButtons
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var warnings: some View {
        if state.hasContrastWarning {
            warningRow(String(format: "前后景对比度过低（%.1f : 1，建议 ≥ 3.0），扫码可能失败", state.contrastRatio))
        }
        if state.hasLogoRatioWarning {
            warningRow("Logo 占比过大（> 30%），扫码可能失败，建议降低到 20% 以内")
        }
    }

    private func warningRow(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(AppFont.caption)
            .foregroundColor(AppColor.warning)
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.warning.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: Radius.m))
    }

    // MARK: - Export

    @ViewBuilder
    private var exportButtons: some View {
        if let image = state.image, let cgImage = state.cgImage {
            #if os(iOS)
            VStack(spacing: Spacing.s) {
                Button {
                    Task { await saveToPhotos(image: image) }
                } label: {
                    Label("保存到相册", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    saveToHistory()
                } label: {
                    Label("保存历史", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                HStack(spacing: Spacing.s) {
                    Button {
                        if let data = PNGExporter.data(from: cgImage) {
                            UIPasteboard.general.image = UIImage(data: data)
                            showStatus("已复制 PNG 到剪贴板", isError: false)
                        }
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    ShareItemsButton(items: [image]) {
                        Label("分享", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            #else
            HStack(spacing: Spacing.s) {
                Button("PNG") { exportMacOS(format: .png, cgImage: cgImage) }
                Button("SVG") { exportMacOS(format: .svg, cgImage: cgImage) }
                Button("PDF") { exportMacOS(format: .pdf, cgImage: cgImage) }
                Button {
                    copyImageMac(cgImage: cgImage)
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
            }
            .buttonStyle(.bordered)
            #endif
        }
    }

    // MARK: - Params

    private var paramsForm: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: Spacing.l) {
            generatorSection("内容") {
                contentEditor
            }

            generatorSection("尺寸 / 边距 / 纠错") {
                Picker("纠错级别", selection: levelBinding) {
                    ForEach(QRErrorCorrectionLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: sizeBinding, in: 256...2048, step: 64) {
                    Text("输出尺寸：\(state.config.sizePx) px")
                }

                Stepper(value: marginBinding, in: 0...10) {
                    Text("外边距：\(state.config.marginModules) 模块")
                }
            }

            if advancedControlsReady {
                generatorSection("形状与配色") {
                    Picker("码点形状", selection: dotShapeBinding) {
                        ForEach(QRDotShape.allCases) { shape in
                            Text(shape.displayName).tag(shape)
                        }
                    }
                    ColorPicker("前景色", selection: foregroundBinding, supportsOpacity: false)
                    ColorPicker("背景色", selection: backgroundBinding, supportsOpacity: false)
                    Text(String(format: "对比度 %.1f : 1", state.contrastRatio))
                        .font(AppFont.caption)
                        .foregroundColor(state.hasContrastWarning ? AppColor.warning : AppColor.textSecondary)
                }

                generatorSection("Logo") {
                    logoControls

                    VStack(alignment: .leading) {
                        Text(String(format: "Logo 占比 %.0f%%", state.config.logoRatio * 100))
                        Slider(value: logoRatioBinding, in: 0.10...0.40, step: 0.01)
                    }
                }
            }
        }
        #else
        Form {
            Section("内容") {
                contentEditor
            }

            Section("尺寸 / 边距 / 纠错") {
                Picker("纠错级别", selection: levelBinding) {
                    ForEach(QRErrorCorrectionLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: sizeBinding, in: 256...2048, step: 64) {
                    Text("输出尺寸：\(state.config.sizePx) px")
                }

                Stepper(value: marginBinding, in: 0...10) {
                    Text("外边距：\(state.config.marginModules) 模块")
                }
            }

            Section("形状与配色") {
                Picker("码点形状", selection: dotShapeBinding) {
                    ForEach(QRDotShape.allCases) { shape in
                        Text(shape.displayName).tag(shape)
                    }
                }
                ColorPicker("前景色", selection: foregroundBinding, supportsOpacity: false)
                ColorPicker("背景色", selection: backgroundBinding, supportsOpacity: false)
                Text(String(format: "对比度 %.1f : 1", state.contrastRatio))
                    .font(AppFont.caption)
                    .foregroundColor(state.hasContrastWarning ? AppColor.warning : AppColor.textSecondary)
            }

            Section("Logo") {
                logoControls

                VStack(alignment: .leading) {
                    Text(String(format: "Logo 占比 %.0f%%", state.config.logoRatio * 100))
                    Slider(value: logoRatioBinding, in: 0.10...0.40, step: 0.01)
                }
            }
        }
        .formStyle(.grouped)
        .padding(Spacing.l)
        #endif
    }

    private var contentEditor: some View {
        ZStack(alignment: .topLeading) {
            if state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("输入文本、网址、Wi-Fi 信息等")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: contentBinding)
                .frame(minHeight: 96)
                .font(AppFont.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
    }

    #if os(iOS)
    private func generatorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, Spacing.s)

            VStack(alignment: .leading, spacing: Spacing.m) {
                content()
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        }
    }
    #endif

    // MARK: - Initial load

    private func startInitialGeneration() async {
        #if os(iOS)
        guard !didStartInitialGeneration else { return }
        didStartInitialGeneration = true

        if hidesTabBar {
            await state.regenerateImmediately()
            return
        }

        await Task.yield()
        try? await Task.sleep(nanoseconds: 120_000_000)
        await state.regenerateImmediately(priority: .utility)

        try? await Task.sleep(nanoseconds: 120_000_000)
        advancedControlsReady = true
        #else
        await state.regenerateImmediately()
        #endif
    }

    @ViewBuilder
    private var logoControls: some View {
        #if os(iOS)
        let hasLogo = state.config.logoData != nil
        let pickerTitle = hasLogo ? "更换 Logo" : "选择 Logo"
        PhotosPicker(selection: $logoPickerItem, matching: .images) {
            Label(pickerTitle, systemImage: "photo")
        }
        if state.config.logoData != nil {
            Button(role: .destructive) {
                state.config.logoData = nil
            } label: {
                Label("移除 Logo", systemImage: "trash")
            }
        }
        #else
        Button(state.config.logoData == nil ? "选择 Logo…" : "更换 Logo…") {
            pickLogoMac()
        }
        if state.config.logoData != nil {
            Button(role: .destructive) {
                state.config.logoData = nil
            } label: {
                Text("移除 Logo")
            }
        }
        #endif
    }

    // MARK: - Save to history

    @ViewBuilder
    private var saveToHistoryButton: some View {
        if state.image != nil {
            Button {
                saveToHistory()
            } label: {
                Label("保存到生成历史", systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func saveToHistory() {
        guard let cgImage = state.cgImage else { return }
        let thumbnail = PNGExporter.data(from: cgImage)
        let record = GeneratedRecord(
            content: state.content,
            config: state.config,
            thumbnailData: thumbnail
        )
        modelContext.insert(record)
        do {
            try modelContext.save()
            showStatus("已加入生成历史", isError: false)
        } catch {
            showStatus("保存到历史失败：\(error.localizedDescription)", isError: true)
        }
    }

    // MARK: - Status banner

    @ViewBuilder
    private var statusBanner: some View {
        if let statusMessage {
            Text(statusMessage)
                .font(AppFont.footnote)
                .padding(Spacing.m)
                .background((statusError ? AppColor.danger : AppColor.accent).opacity(0.85))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: Radius.m))
                .padding(Spacing.l)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func showStatus(_ message: String, isError: Bool) {
        statusError = isError
        statusMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    // MARK: - Bindings

    private var contentBinding: Binding<String> {
        Binding(get: { state.content }, set: { state.content = $0 })
    }

    private var levelBinding: Binding<QRErrorCorrectionLevel> {
        Binding(get: { state.config.correctionLevel }, set: { state.config.correctionLevel = $0 })
    }

    private var sizeBinding: Binding<Int> {
        Binding(get: { state.config.sizePx }, set: { state.config.sizePx = $0 })
    }

    private var marginBinding: Binding<Int> {
        Binding(get: { state.config.marginModules }, set: { state.config.marginModules = $0 })
    }

    private var dotShapeBinding: Binding<QRDotShape> {
        Binding(get: { state.config.dotShape }, set: { state.config.dotShape = $0 })
    }

    private var logoRatioBinding: Binding<Double> {
        Binding(get: { state.config.logoRatio }, set: { state.config.logoRatio = $0 })
    }

    private var foregroundBinding: Binding<Color> {
        Binding(
            get: { HexColor(hex: state.config.foregroundHex)?.swiftUIColor ?? .black },
            set: { state.config.foregroundHex = HexColor(color: $0).hex }
        )
    }

    private var backgroundBinding: Binding<Color> {
        Binding(
            get: { HexColor(hex: state.config.backgroundHex)?.swiftUIColor ?? .white },
            set: { state.config.backgroundHex = HexColor(color: $0).hex }
        )
    }

    // MARK: - Platform-specific actions

    #if os(iOS)
    private func loadPickedLogo(item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                state.config.logoData = data
            }
        } catch {
            showStatus("Logo 读取失败：\(error.localizedDescription)", isError: true)
        }
    }

    private func saveToPhotos(image: UIImage) async {
        do {
            try await PhotoLibrarySaver.save(image)
            showStatus("已保存到相册", isError: false)
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }
    #else
    private enum MacExportFormat {
        case png, svg, pdf

        var contentType: UTType {
            switch self {
            case .png: return .png
            case .svg: return UTType(filenameExtension: "svg") ?? .data
            case .pdf: return .pdf
            }
        }

        var suggestedExt: String {
            switch self {
            case .png: return "png"
            case .svg: return "svg"
            case .pdf: return "pdf"
            }
        }
    }

    private func exportMacOS(format: MacExportFormat, cgImage: CGImage) {
        guard let matrix = state.bitMatrix else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = "QRScan-Pro.\(format.suggestedExt)"

        var scopedURL: URL?
        if let bookmark = settings.defaultExportDirectoryBookmark,
           let url = ExportDirectoryBookmark.resolve(bookmark) {
            if url.startAccessingSecurityScopedResource() {
                scopedURL = url
                panel.directoryURL = url
            }
        }
        defer { scopedURL?.stopAccessingSecurityScopedResource() }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let data: Data?
        switch format {
        case .png:
            data = PNGExporter.data(from: cgImage)
        case .svg:
            data = SVGExporter.data(matrix: matrix, config: state.config)
        case .pdf:
            data = PDFExporter.data(from: cgImage)
        }

        guard let payload = data else {
            showStatus("导出失败：编码错误", isError: true)
            return
        }
        do {
            try payload.write(to: url)
            showStatus("已导出到 \(url.lastPathComponent)", isError: false)
        } catch {
            showStatus("导出失败：\(error.localizedDescription)", isError: true)
        }
    }

    private func copyImageMac(cgImage: CGImage) {
        guard let data = PNGExporter.data(from: cgImage) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
        showStatus("已复制 PNG 到剪贴板", isError: false)
    }

    private func pickLogoMac() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            state.config.logoData = try Data(contentsOf: url)
        } catch {
            showStatus("Logo 读取失败：\(error.localizedDescription)", isError: true)
        }
    }
    #endif
}
