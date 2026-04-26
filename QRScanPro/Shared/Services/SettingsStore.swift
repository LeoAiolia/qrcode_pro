import Foundation
import Observation

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        }
    }
}

enum HistoryRetention: String, Codable, CaseIterable, Identifiable {
    case forever
    case thirtyDays
    case ninetyDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forever:
            return "永久"
        case .thirtyDays:
            return "30 天"
        case .ninetyDays:
            return "90 天"
        }
    }

    /// 返回保留窗口起点（早于此时间的记录可清理）；nil 表示永久保留。
    func cutoffDate(now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .forever:
            return nil
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .ninetyDays:
            return calendar.date(byAdding: .day, value: -90, to: now)
        }
    }
}

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case png
    case svg
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .png:
            return "PNG"
        case .svg:
            return "SVG"
        case .pdf:
            return "PDF"
        }
    }
}

/// 全局设置容器；UserDefaults 后端，所有写入即时持久化。
/// 替代旧 AppStore 的设置部分；历史记录由 HistoryRepository 单独负责。
@MainActor
@Observable
final class SettingsStore {
    var enabledKinds: Set<BarcodeKind> {
        didSet { write(\.enabledKinds, oldValue) }
    }
    var vibrationEnabled: Bool {
        didSet { write(\.vibrationEnabled, oldValue) }
    }
    var soundEnabled: Bool {
        didSet { write(\.soundEnabled, oldValue) }
    }
    var continuousScanEnabled: Bool {
        didSet { write(\.continuousScanEnabled, oldValue) }
    }
    var appearance: AppAppearance {
        didSet { write(\.appearance, oldValue) }
    }
    var historyRetention: HistoryRetention {
        didSet { write(\.historyRetention, oldValue) }
    }
    var defaultExportFormat: ExportFormat {
        didSet { write(\.defaultExportFormat, oldValue) }
    }
    /// macOS 默认导出目录的 Bookmark Data；nil 表示每次询问。
    var defaultExportDirectoryBookmark: Data? {
        didSet { write(\.defaultExportDirectoryBookmark, oldValue) }
    }

    private let defaults: UserDefaults
    private var isLoading = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isLoading = true

        let snapshot = Self.loadSnapshot(from: defaults)
        self.enabledKinds = snapshot.enabledKinds
        self.vibrationEnabled = snapshot.vibrationEnabled
        self.soundEnabled = snapshot.soundEnabled
        self.continuousScanEnabled = snapshot.continuousScanEnabled
        self.appearance = snapshot.appearance
        self.historyRetention = snapshot.historyRetention
        self.defaultExportFormat = snapshot.defaultExportFormat
        self.defaultExportDirectoryBookmark = snapshot.defaultExportDirectoryBookmark

        self.isLoading = false
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var enabledKinds: Set<BarcodeKind>
        var vibrationEnabled: Bool
        var soundEnabled: Bool
        var continuousScanEnabled: Bool
        var appearance: AppAppearance
        var historyRetention: HistoryRetention
        var defaultExportFormat: ExportFormat
        var defaultExportDirectoryBookmark: Data?

        static let `default` = Snapshot(
            enabledKinds: Set(BarcodeKind.allCases),
            vibrationEnabled: true,
            soundEnabled: true,
            continuousScanEnabled: false,
            appearance: .system,
            historyRetention: .forever,
            defaultExportFormat: .png,
            defaultExportDirectoryBookmark: nil
        )
    }

    private static let storageKey = "qrscanpro.settings.v2"

    private static func loadSnapshot(from defaults: UserDefaults) -> Snapshot {
        guard let data = defaults.data(forKey: storageKey) else {
            return .default
        }
        return (try? JSONDecoder().decode(Snapshot.self, from: data)) ?? .default
    }

    private func write<Value>(_ keyPath: KeyPath<Snapshot, Value>, _ oldValue: Value) {
        guard !isLoading else { return }
        persist()
    }

    private func persist() {
        let snapshot = Snapshot(
            enabledKinds: enabledKinds,
            vibrationEnabled: vibrationEnabled,
            soundEnabled: soundEnabled,
            continuousScanEnabled: continuousScanEnabled,
            appearance: appearance,
            historyRetention: historyRetention,
            defaultExportFormat: defaultExportFormat,
            defaultExportDirectoryBookmark: defaultExportDirectoryBookmark
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            assertionFailure("设置序列化失败：\(error.localizedDescription)")
        }
    }
}
