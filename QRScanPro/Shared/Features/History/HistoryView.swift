import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var filter: HistoryFilter = .all
    @State private var selectedResult: ScanResult?

    var body: some View {
        List {
            Section {
                searchField
                filterPicker
            }
            .listRowBackground(AppTheme.surface)

            Section {
                if filteredHistory.isEmpty {
                    emptyState
                        .listRowBackground(AppTheme.surface)
                } else {
                    ForEach(filteredHistory) { result in
                        Button {
                            selectedResult = result
                        } label: {
                            HistoryRow(result: result)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.surface)
                    }
                    .onDelete { indexSet in
                        indexSet.map { filteredHistory[$0] }.forEach(store.deleteResult)
                    }
                }
            }
        }
        .hideScrollBackgroundWhenAvailable()
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("历史记录")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    store.clearHistory()
                } label: {
                    Label("清空", systemImage: "trash")
                }
                .disabled(store.history.isEmpty)
            }
        }
        .sheet(item: $selectedResult) { result in
            NavigationView {
                ScanResultView(result: result)
            }
        }
    }

    private var searchField: some View {
        TextField("搜索扫描内容", text: $query)
            .textFieldStyle(.roundedBorder)
    }

    private var filterPicker: some View {
        Picker("筛选", selection: $filter) {
            ForEach(HistoryFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundColor(AppTheme.textSecondary)
            Text("暂无历史记录")
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var filteredHistory: [ScanResult] {
        store.history.filter { result in
            matchesQuery(result) && matchesFilter(result)
        }
    }

    private func matchesQuery(_ result: ScanResult) -> Bool {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true
        }
        return result.value.localizedCaseInsensitiveContains(query)
    }

    private func matchesFilter(_ result: ScanResult) -> Bool {
        switch filter {
        case .all:
            return true
        case .qr:
            switch result.kind {
            case .qr:
                return true
            case .ean13, .ean8, .upce, .code128, .code39, .pdf417, .aztec, .dataMatrix, .unknown:
                return false
            }
        case .barcode:
            switch result.kind {
            case .qr:
                return false
            case .ean13, .ean8, .upce, .code128, .code39, .pdf417, .aztec, .dataMatrix, .unknown:
                return true
            }
        case .image:
            switch result.source {
            case .image:
                return true
            case .camera:
                return false
            }
        case .today:
            return Calendar.current.isDateInToday(result.createdAt)
        }
    }
}

struct HistoryRow: View {
    let result: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(result.value)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("\(result.kind.displayName) · \(result.source.displayName) · \(result.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    private var iconName: String {
        switch result.kind {
        case .qr:
            return "qrcode"
        case .ean13, .ean8, .upce, .code128, .code39, .pdf417, .aztec, .dataMatrix, .unknown:
            return "barcode"
        }
    }
}
