import Foundation

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
}

struct AppSettings: Codable, Equatable {
    var enabledKinds: Set<BarcodeKind>
    var vibrationEnabled: Bool
    var soundEnabled: Bool
    var continuousScanEnabled: Bool
    var appearance: AppAppearance
    var historyRetention: HistoryRetention

    static let `default` = AppSettings(
        enabledKinds: [.qr, .ean13, .ean8, .upce, .code128, .code39],
        vibrationEnabled: true,
        soundEnabled: true,
        continuousScanEnabled: false,
        appearance: .dark,
        historyRetention: .forever
    )
}
