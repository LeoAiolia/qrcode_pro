#if os(macOS)
import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// macOS 图片识别主页：拖拽 + NSOpenPanel 多选 → recognizeAll → 当次会话结果列表（不持久化）。
struct MacImageRecognitionView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @State private var sessionResults: [RecognitionEntry] = []
    @State private var isRecognizing = false
    @State private var errorMessage: String?
    @State private var isDropTargeted = false

    private let recognizer = BarcodeImageRecognizer()

    var body: some View {
        VStack(spacing: 0) {
            header

            if sessionResults.isEmpty {
                dropZone
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultList
            }
        }
        .background(AppColor.background)
        .navigationTitle("图片识别")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    selectImages()
                } label: {
                    Label("选择图片", systemImage: "photo")
                }
                .disabled(isRecognizing)

                Button {
                    copyAll()
                } label: {
                    Label("全部复制", systemImage: "doc.on.doc")
                }
                .disabled(sessionResults.isEmpty)

                Button {
                    exportCSV()
                } label: {
                    Label("导出 CSV", systemImage: "square.and.arrow.down")
                }
                .disabled(sessionResults.isEmpty)

                Button(role: .destructive) {
                    sessionResults.removeAll()
                } label: {
                    Label("清空", systemImage: "trash")
                }
                .disabled(sessionResults.isEmpty)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay(alignment: .top) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.footnote)
                    .padding(Spacing.m)
                    .background(AppColor.danger.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.m))
                    .padding(Spacing.l)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("拖入图片或点击右上角选择，本地完成多码识别。")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textPrimary)
                Text("识别成功的结果将自动写入扫码历史。")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            if isRecognizing {
                ProgressView().scaleEffect(0.8)
            }
        }
        .padding(Spacing.l)
        .background(AppColor.surface)
    }

    private var dropZone: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(AppColor.accent.opacity(isDropTargeted ? 1 : 0.7))

            Text(isDropTargeted ? "松手以识别" : "拖入图片到此处")
                .font(AppFont.title)
                .foregroundColor(AppColor.textPrimary)

            Text("支持 PNG / JPEG / HEIC 等常见格式。")
                .font(AppFont.footnote)
                .foregroundColor(AppColor.textSecondary)

            Button("选择图片…") { selectImages() }
                .buttonStyle(.borderedProminent)
                .disabled(isRecognizing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(
                    AppColor.accent.opacity(isDropTargeted ? 0.6 : 0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(Spacing.l)
        )
    }

    private var resultList: some View {
        List {
            ForEach(sessionResults) { entry in
                ResultRow(entry: entry) {
                    if let value = entry.code?.value {
                        ClipboardService.copy(value)
                    }
                } openURL: {
                    if let url = entry.code?.url {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Actions

    private func selectImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK else { return }
        recognize(urls: panel.urls)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    urls.append(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            recognize(urls: urls)
        }
        return !providers.isEmpty
    }

    private func recognize(urls: [URL]) {
        guard !urls.isEmpty else { return }
        isRecognizing = true
        errorMessage = nil

        Task {
            var newEntries: [RecognitionEntry] = []
            for url in urls {
                guard
                    let image = NSImage(contentsOf: url),
                    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                else {
                    DebugLogger.shared.warning("无法读取图片：\(url.lastPathComponent)")
                    continue
                }

                do {
                    let codes = try await recognizer.recognizeAll(
                        cgImage: cgImage,
                        allowedKinds: settings.enabledKinds
                    )
                    if codes.isEmpty {
                        newEntries.append(
                            RecognitionEntry(
                                fileName: url.lastPathComponent,
                                code: nil
                            )
                        )
                    } else {
                        for code in codes {
                            newEntries.append(
                                RecognitionEntry(
                                    fileName: url.lastPathComponent,
                                    code: code
                                )
                            )
                        }
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                for entry in newEntries {
                    guard let code = entry.code else { continue }
                    let record = ScanRecord(value: code.value, kind: code.kind, source: .image)
                    modelContext.insert(record)
                }
                try? modelContext.save()

                sessionResults.insert(contentsOf: newEntries, at: 0)
                isRecognizing = false
            }
        }
    }

    private func copyAll() {
        let lines = sessionResults.compactMap { $0.code?.value }
        guard !lines.isEmpty else { return }
        ClipboardService.copy(lines.joined(separator: "\n"))
    }

    private func exportCSV() {
        let codes = sessionResults.compactMap { $0.code }
        guard !codes.isEmpty else {
            errorMessage = "当前没有可导出的识别结果"
            return
        }
        do {
            let csv = FileExporter.csv(from: codes)
            _ = try FileExporter.saveCSV(csv)
        } catch FileExporterError.userCancelled {
            // 静默
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Models

private struct RecognitionEntry: Identifiable {
    let id = UUID()
    let fileName: String
    let code: RecognizedCode?
}

private struct ResultRow: View {
    let entry: RecognitionEntry
    let copyAction: () -> Void
    let openURL: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(entry.code == nil ? AppColor.textSecondary : AppColor.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.fileName)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                if let code = entry.code {
                    Text(code.value)
                        .font(AppFont.mono)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(2)
                    Text(code.kind.displayName)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.accent)
                } else {
                    Text("未识别到二维码 / 条形码")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                }
            }

            Spacer()

            if entry.code != nil {
                Button(action: copyAction) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("复制内容")
                .accessibilityLabel("复制识别内容")

                if entry.code?.url != nil {
                    Button(action: openURL) {
                        Image(systemName: "safari")
                    }
                    .buttonStyle(.borderless)
                    .help("打开链接")
                    .accessibilityLabel("在浏览器中打开")
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var iconName: String {
        guard let code = entry.code else { return "questionmark.square" }
        return code.kind.isMatrixCode ? "qrcode" : "barcode"
    }
}
#endif
