import SwiftData
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum HistoryKindFilter: String, CaseIterable, Identifiable {
    case all
    case matrix
    case linear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .matrix: return "二维码"
        case .linear: return "条形码"
        }
    }

    func matches(_ kind: BarcodeKind) -> Bool {
        switch self {
        case .all: return true
        case .matrix: return kind.isMatrixCode
        case .linear: return !kind.isMatrixCode
        }
    }
}

enum HistorySourceFilter: String, CaseIterable, Identifiable {
    case all
    case camera
    case image

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .camera: return "相机"
        case .image: return "图片"
        }
    }

    func matches(_ source: ScanSource) -> Bool {
        switch self {
        case .all: return true
        case .camera: return source == .camera
        case .image: return source == .image
        }
    }
}

private enum HistorySegment: String, CaseIterable, Identifiable {
    case scan
    case generated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: return "扫码"
        case .generated: return "生成"
        }
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    #if os(iOS)
    @State private var segment: HistorySegment = .scan
    #endif

    @State private var query: String = ""
    @State private var kindFilter: HistoryKindFilter = .all
    @State private var sourceFilter: HistorySourceFilter = .all
    @State private var todayOnly: Bool = false
    @State private var scanSelection = Set<UUID>()
    @State private var generatedSelection = Set<UUID>()

    @Query(sort: [SortDescriptor(\ScanRecord.createdAt, order: .reverse)])
    private var scans: [ScanRecord]

    @Query(sort: [SortDescriptor(\GeneratedRecord.createdAt, order: .reverse)])
    private var generated: [GeneratedRecord]

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            Picker("分段", selection: $segment) {
                ForEach(HistorySegment.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.s)
            #endif

            filterBar

            list
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("历史记录")
        .toolbar { toolbarContent }
        .searchable(text: $query, prompt: "搜索内容")
    }

    // MARK: - Filter

    @ViewBuilder
    private var filterBar: some View {
        let showSource: Bool = {
            #if os(iOS)
            return segment == .scan
            #else
            return false
            #endif
        }()
        let showKind: Bool = {
            #if os(iOS)
            return segment == .scan
            #else
            return false
            #endif
        }()

        VStack(spacing: Spacing.s) {
            if showKind {
                Picker("码制", selection: $kindFilter) {
                    ForEach(HistoryKindFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if showSource {
                Picker("来源", selection: $sourceFilter) {
                    ForEach(HistorySourceFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Toggle("仅今天", isOn: $todayOnly)
                .toggleStyle(.switch)
                .font(AppFont.footnote)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        #if os(iOS)
        switch segment {
        case .scan:
            scanList
        case .generated:
            generatedList
        }
        #else
        generatedList
        #endif
    }

    private var scanList: some View {
        let items = filteredScans
        return Group {
            if items.isEmpty {
                emptyState(message: "暂无扫码记录")
            } else {
                List(selection: $scanSelection) {
                    ForEach(items) { record in
                        NavigationLink(value: record) {
                            ScanRow(record: record)
                        }
                        .tag(record.id)
                    }
                    .onDelete { offsets in
                        offsets.map { items[$0] }.forEach(deleteScan)
                    }
                }
                .navigationDestination(for: ScanRecord.self) { record in
                    ScanResultView(record: record)
                }
            }
        }
    }

    private var generatedList: some View {
        let items = filteredGenerated
        return Group {
            if items.isEmpty {
                emptyState(message: "暂无生成记录")
            } else {
                List(selection: $generatedSelection) {
                    ForEach(items) { record in
                        NavigationLink(value: record) {
                            GeneratedRow(record: record)
                        }
                        .tag(record.id)
                    }
                    .onDelete { offsets in
                        offsets.map { items[$0] }.forEach(deleteGenerated)
                    }
                }
                .navigationDestination(for: GeneratedRecord.self) { record in
                    GeneratorView(initialContent: record.content, initialConfig: record.config)
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColor.textSecondary)
            Text(message)
                .font(AppFont.body)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
        ToolbarItem(placement: .topBarLeading) {
            if !currentSelection.isEmpty {
                Button(role: .destructive) {
                    deleteSelection()
                } label: {
                    Label("删除选中(\(currentSelection.count))", systemImage: "trash")
                }
            }
        }
        #else
        ToolbarItem {
            if !currentSelection.isEmpty {
                Button(role: .destructive) {
                    deleteSelection()
                } label: {
                    Label("删除选中(\(currentSelection.count))", systemImage: "trash")
                }
            }
        }
        #endif

        ToolbarItem(placement: .automatic) {
            Menu {
                Button(role: .destructive) {
                    clearAll()
                } label: {
                    Label("清空全部", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("更多操作")
        }
    }

    private var currentSelection: Set<UUID> {
        #if os(iOS)
        return segment == .scan ? scanSelection : generatedSelection
        #else
        return generatedSelection
        #endif
    }

    // MARK: - Filtering

    private var filteredScans: [ScanRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let cal = Calendar.current
        return scans.filter { record in
            kindFilter.matches(record.kind)
                && sourceFilter.matches(record.source)
                && (!todayOnly || cal.isDateInToday(record.createdAt))
                && (trimmed.isEmpty || record.value.localizedCaseInsensitiveContains(trimmed))
        }
    }

    private var filteredGenerated: [GeneratedRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let cal = Calendar.current
        return generated.filter { record in
            (!todayOnly || cal.isDateInToday(record.createdAt))
                && (trimmed.isEmpty || record.content.localizedCaseInsensitiveContains(trimmed))
        }
    }

    // MARK: - Mutations

    private func deleteScan(_ record: ScanRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func deleteGenerated(_ record: GeneratedRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func deleteSelection() {
        #if os(iOS)
        if segment == .scan {
            scans.filter { scanSelection.contains($0.id) }.forEach(deleteScan)
            scanSelection.removeAll()
        } else {
            generated.filter { generatedSelection.contains($0.id) }.forEach(deleteGenerated)
            generatedSelection.removeAll()
        }
        #else
        generated.filter { generatedSelection.contains($0.id) }.forEach(deleteGenerated)
        generatedSelection.removeAll()
        #endif
    }

    private func clearAll() {
        do {
            try modelContext.delete(model: ScanRecord.self)
            try modelContext.delete(model: GeneratedRecord.self)
            try modelContext.save()
        } catch {
            DebugLogger.shared.error("清空历史失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - Rows

private struct ScanRow: View {
    let record: ScanRecord

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: record.kind.isMatrixCode ? "qrcode" : "barcode")
                .font(.title3)
                .foregroundColor(AppColor.accent)
                .frame(width: 36, height: 36)
                .background(AppColor.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Radius.m))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.value)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                Text("\(record.kind.displayName) · \(record.source.displayName) · \(record.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct GeneratedRow: View {
    let record: GeneratedRecord

    var body: some View {
        HStack(spacing: Spacing.m) {
            thumbnail
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: Radius.m))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.content)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                Text("\(record.config.sizePx) px · \(record.config.dotShape.displayName) · \(record.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = record.thumbnailData, let image = decodeImage(data) {
            #if os(iOS)
            Image(uiImage: image).resizable().interpolation(.none).scaledToFit().padding(2)
            #elseif os(macOS)
            Image(nsImage: image).resizable().interpolation(.none).scaledToFit().padding(2)
            #endif
        } else {
            Image(systemName: "qrcode")
                .foregroundColor(AppColor.textSecondary)
        }
    }

    private func decodeImage(_ data: Data) -> PlatformImage? {
        #if os(iOS)
        return UIImage(data: data)
        #elseif os(macOS)
        return NSImage(data: data)
        #endif
    }
}
