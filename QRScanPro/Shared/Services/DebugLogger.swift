import Foundation
import OSLog

struct DebugLogEntry: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let level: DebugLogLevel
    let message: String

    init(id: UUID = UUID(), date: Date = Date(), level: DebugLogLevel, message: String) {
        self.id = id
        self.date = date
        self.level = level
        self.message = message
    }
}

enum DebugLogLevel: String {
    case info
    case warning
    case error

    var title: String {
        switch self {
        case .info:
            return "信息"
        case .warning:
            return "警告"
        case .error:
            return "错误"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        }
    }
}

final class DebugLogger: ObservableObject {
    @Published private(set) var entries: [DebugLogEntry] = []

    private let logger = Logger(subsystem: "com.yuxiaor.qrscnpro", category: "app")
    private let maxEntries = 300

    func info(_ message: String) {
        append(level: .info, message: message)
    }

    func warning(_ message: String) {
        append(level: .warning, message: message)
    }

    func error(_ message: String) {
        append(level: .error, message: message)
    }

    func clear() {
        entries.removeAll()
        logger.info("调试日志已清空")
    }

    private func append(level: DebugLogLevel, message: String) {
        let entry = DebugLogEntry(level: level, message: message)
        entries.insert(entry, at: 0)

        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }

        logger.log(level: level.osLogType, "\(message, privacy: .public)")
    }
}
