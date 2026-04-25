import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    @Published private(set) var history: [ScanResult] = []
    let logger = DebugLogger()

    private let storage = LocalStorage()

    init() {
        settings = storage.loadSettings()
        history = storage.loadHistory()
        applyRetentionPolicy()
        logger.info("应用状态初始化完成")
    }

    func addResult(_ result: ScanResult) {
        guard !result.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("忽略空白扫描结果")
            return
        }

        history.insert(result, at: 0)
        storage.saveHistory(history)
        logger.info("新增识别记录：\(result.kind.displayName)")
    }

    func deleteResult(_ result: ScanResult) {
        history.removeAll { item in
            item.id == result.id
        }
        storage.saveHistory(history)
        logger.info("删除识别记录")
    }

    func clearHistory() {
        history.removeAll()
        storage.saveHistory(history)
        logger.info("历史记录已清空")
    }

    private func saveSettings() {
        storage.saveSettings(settings)
        logger.info("设置已保存")
    }

    private func applyRetentionPolicy() {
        let calendar = Calendar.current
        let now = Date()
        let filteredHistory: [ScanResult]

        switch settings.historyRetention {
        case .forever:
            filteredHistory = history
        case .thirtyDays:
            filteredHistory = history.filter { result in
                guard let boundary = calendar.date(byAdding: .day, value: -30, to: now) else {
                    return true
                }
                return result.createdAt >= boundary
            }
        case .ninetyDays:
            filteredHistory = history.filter { result in
                guard let boundary = calendar.date(byAdding: .day, value: -90, to: now) else {
                    return true
                }
                return result.createdAt >= boundary
            }
        }

        if filteredHistory.count != history.count {
            history = filteredHistory
            storage.saveHistory(history)
            logger.info("已按保留时长清理历史记录")
        }
    }
}
