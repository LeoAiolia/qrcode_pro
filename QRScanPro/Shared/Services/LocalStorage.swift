import Foundation

struct LocalStorage {
    private let defaults = UserDefaults.standard
    private let settingsKey = "qrscanpro.settings"
    private let historyKey = "qrscanpro.history"

    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return .default
        }

        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            return .default
        }
    }

    func saveSettings(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: settingsKey)
        } catch {
            assertionFailure("设置保存失败：\(error.localizedDescription)")
        }
    }

    func loadHistory() -> [ScanResult] {
        guard let data = defaults.data(forKey: historyKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ScanResult].self, from: data)
        } catch {
            return []
        }
    }

    func saveHistory(_ history: [ScanResult]) {
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: historyKey)
        } catch {
            assertionFailure("历史记录保存失败：\(error.localizedDescription)")
        }
    }
}
