#if os(macOS)
import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Route

enum MacImageRecognitionRoute: Hashable {
    case results
    case scanResult(ScanRecord)
}

// MARK: - State

@Observable
final class MacImageRecognitionState {
    var results: [RecognitionEntry] = []
    var path: [MacImageRecognitionRoute] = []
    var isRecognizing: Bool = false
    var errorMessage: String?
    var isDropTargeted: Bool = false
}

// MARK: - Model

struct RecognitionEntry: Identifiable {
    let id = UUID()
    let fileName: String
    let code: RecognizedCode?
    /// 成功识别的条目入库后的记录引用，用于跳转扫描结果页
    var record: ScanRecord?
}

// MARK: - Main View

struct MacImageRecognitionView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SwiftDataHistoryRepository.self) private var historyRepository
    @Bindable var state: MacImageRecognitionState

    private let recognizer = BarcodeImageRecognizer()

    var body: some View {
        NavigationStack(path: $state.path) {
            dropZonePage
                .navigationDestination(for: MacImageRecognitionRoute.self) { route in
                    switch route {
                    case .results:
                        RecognitionResultsView(state: state)
                    case .scanResult(let record):
                        ScanResultView(record: record)
                    }
                }
        }
    }

    // MARK: - Drop Zone Page

    private var dropZonePage: some View {
        Group {
            if state.isRecognizing {
                VStack(spacing: Spacing.l) {
                    ProgressView()
                    Text("识别中…")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                dropZoneContent
            }
        }
        .background(AppColor.background)
        .navigationTitle("图片识别")
        .toolbar {
            ToolbarItem {
                Button { selectImages() } label: {
                    Label("选择图片", systemImage: "photo")
                }
                .disabled(state.isRecognizing)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $state.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay(alignment: .top) { errorBanner }
    }

    private var dropZoneContent: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(AppColor.accent.opacity(state.isDropTargeted ? 1 : 0.7))

            Text(state.isDropTargeted ? "松手以识别" : "拖入图片到此处")
                .font(AppFont.title)
                .foregroundColor(AppColor.textPrimary)

            Text("支持 PNG / JPEG / HEIC 等常见格式，识别成功结果自动写入扫码历史。")
                .font(AppFont.footnote)
                .foregroundColor(AppColor.textSecondary)

            Button("选择图片…") { selectImages() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(
                    AppColor.accent.opacity(state.isDropTargeted ? 0.6 : 0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(Spacing.l)
        )
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let msg = state.errorMessage {
            Text(msg)
                .font(AppFont.footnote)
                .padding(Spacing.m)
                .background(AppColor.danger.opacity(0.85))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: Radius.m))
                .padding(Spacing.l)
        }
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
                if let url { urls.append(url) }
                group.leave()
            }
        }
        group.notify(queue: .main) { recognize(urls: urls) }
        return !providers.isEmpty
    }

    private func recognize(urls: [URL]) {
        guard !urls.isEmpty else { return }
        state.isRecognizing = true
        state.errorMessage = nil

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
                        newEntries.append(RecognitionEntry(fileName: url.lastPathComponent, code: nil))
                    } else {
                        for code in codes {
                            newEntries.append(RecognitionEntry(fileName: url.lastPathComponent, code: code))
                        }
                    }
                } catch {
                    state.errorMessage = error.localizedDescription
                }
            }

            await MainActor.run {
                // 入库并回填引用，成功条目据此可跳转扫描结果页（与历史记录一致）
                var records: [ScanRecord] = []
                for index in newEntries.indices {
                    guard let code = newEntries[index].code else { continue }
                    let record = ScanRecord(value: code.value, kind: code.kind, source: .image)
                    newEntries[index].record = record
                    records.append(record)
                }
                do {
                    try historyRepository.addScans(records)
                } catch {
                    DebugLogger.shared.error("图片识别入库失败：\(error.localizedDescription)")
                }

                state.results = newEntries
                state.isRecognizing = false
                if !newEntries.isEmpty {
                    state.path = [.results]
                }
            }
        }
    }
}

// MARK: - Results Page

private struct RecognitionResultsView: View {
    @Bindable var state: MacImageRecognitionState
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    private var successCount: Int { state.results.filter { $0.code != nil }.count }
    private var failCount: Int { state.results.count - successCount }

    var body: some View {
        VStack(spacing: 0) {
            summaryBar
            Divider()
            resultList
        }
        .background(AppColor.background)
        .navigationTitle("识别结果（\(successCount) / \(state.results.count) 条）")
        .toolbar { toolbarContent }
        .overlay(alignment: .bottom) { toast }
    }

    // MARK: Summary Bar

    private var summaryBar: some View {
        HStack(spacing: Spacing.m) {
            Label("\(successCount) 条已识别", systemImage: "checkmark.seal.fill")
                .foregroundColor(successCount > 0 ? AppColor.success : AppColor.textSecondary)

            if failCount > 0 {
                Text("·")
                    .foregroundColor(AppColor.textTertiary)
                Label("\(failCount) 张未识别", systemImage: "xmark.circle")
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
        .font(AppFont.footnote)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .background(AppColor.surface)
    }

    // MARK: List

    private var resultList: some View {
        List {
            ForEach(state.results) { entry in
                row(for: entry)
            }
        }
        .listStyle(.inset)
    }

    @ViewBuilder
    private func row(for entry: RecognitionEntry) -> some View {
        let row = ResultRow(entry: entry) {
            if let value = entry.code?.value {
                ClipboardService.copy(value)
                showToast("已复制")
            }
        } openURL: {
            if let url = entry.code?.url {
                NSWorkspace.shared.open(url)
            }
        }

        if let record = entry.record, !record.isDeleted {
            NavigationLink(value: MacImageRecognitionRoute.scanResult(record)) {
                row
            }
        } else {
            row
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                let lines = state.results.compactMap { $0.code?.value }
                ClipboardService.copy(lines.joined(separator: "\n"))
                showToast("已复制 \(lines.count) 条")
            } label: {
                Label("全部复制", systemImage: "doc.on.doc")
            }
            .disabled(successCount == 0)

            Button { exportCSV() } label: {
                Label("导出 CSV", systemImage: "square.and.arrow.down")
            }
            .disabled(successCount == 0)

            Button(role: .destructive) {
                state.results.removeAll()
                state.path.removeAll()
            } label: {
                Label("清空", systemImage: "trash")
            }
        }
    }

    // MARK: Toast

    @ViewBuilder
    private var toast: some View {
        if let msg = toastMessage {
            HStack(spacing: Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColor.success)
                Text(msg)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textPrimary)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s + 2)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.l))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
            .padding(.bottom, Spacing.l)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.25)) {
            toastMessage = message
        }
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    toastMessage = nil
                }
            }
        }
    }

    // MARK: Export

    private func exportCSV() {
        let codes = state.results.compactMap { $0.code }
        do {
            let csv = FileExporter.csv(from: codes)
            _ = try FileExporter.saveCSV(csv)
        } catch FileExporterError.userCancelled {
            // 静默
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Result Row

private struct ResultRow: View {
    let entry: RecognitionEntry
    let copyAction: () -> Void
    let openURL: () -> Void

    @State private var copied = false

    private var isSuccess: Bool { entry.code != nil }

    var body: some View {
        HStack(spacing: Spacing.m) {
            iconBadge
            content
            Spacer()
            if isSuccess { actionButtons }
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    private var iconBadge: some View {
        let iconName: String = {
            guard let code = entry.code else { return "xmark" }
            return code.kind.isMatrixCode ? "qrcode" : "barcode"
        }()
        return Image(systemName: iconName)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(isSuccess ? AppColor.accent : AppColor.textTertiary)
            .frame(width: 44, height: 44)
            .background(isSuccess ? AppColor.accent.opacity(0.12) : AppColor.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(entry.fileName)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(1)

            if let code = entry.code {
                Text(code.value)
                    .font(AppFont.mono)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text(code.kind.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColor.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
            } else {
                Text("未识别到二维码 / 条形码")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textSecondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.s) {
            Button {
                copyAction()
                withAnimation(.spring(duration: 0.2)) { copied = true }
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.2)) { copied = false }
                    }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .frame(width: 16, height: 16)
                    .foregroundColor(copied ? AppColor.success : AppColor.accent)
            }
            .buttonStyle(.borderless)
            .help("复制内容")

            if entry.code?.url != nil {
                Button(action: openURL) {
                    Image(systemName: "safari")
                        .foregroundColor(AppColor.accent)
                }
                .buttonStyle(.borderless)
                .help("在浏览器中打开")
            }
        }
    }
}
#endif
