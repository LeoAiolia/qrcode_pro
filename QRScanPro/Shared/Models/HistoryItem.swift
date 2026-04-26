import Foundation

/// 视图层聚合：把 ScanRecord / GeneratedRecord 统一成单一 sealed enum，
/// 便于历史页混排、详情页路由。持久化层仍各自存表。
enum HistoryItem: Identifiable, Hashable {
    case scan(ScanRecord)
    case generated(GeneratedRecord)

    var id: UUID {
        switch self {
        case .scan(let record):
            return record.id
        case .generated(let record):
            return record.id
        }
    }

    var createdAt: Date {
        switch self {
        case .scan(let record):
            return record.createdAt
        case .generated(let record):
            return record.createdAt
        }
    }

    var displayValue: String {
        switch self {
        case .scan(let record):
            return record.value
        case .generated(let record):
            return record.content
        }
    }
}
