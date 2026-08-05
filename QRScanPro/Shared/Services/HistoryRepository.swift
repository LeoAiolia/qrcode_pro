import Foundation
import SwiftData

/// 历史记录读写抽象；视图层禁止直连 ModelContext，统一走此协议。
@MainActor
protocol HistoryRepository {
    func addScan(_ record: ScanRecord) throws
    func addGenerated(_ record: GeneratedRecord) throws
    func deleteScan(_ record: ScanRecord) throws
    func deleteGenerated(_ record: GeneratedRecord) throws
    func clearAll() throws
    func applyRetention(_ retention: HistoryRetention, now: Date) throws
}

enum HistoryRepositoryError: LocalizedError {
    case persistenceFailure(String)

    var errorDescription: String? {
        switch self {
        case .persistenceFailure(let message):
            return "历史记录写入失败：\(message)"
        }
    }
}

/// SwiftData 实现；ModelContext 由调用方注入，便于 InMemory 替换。
@MainActor
final class SwiftDataHistoryRepository: HistoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addScan(_ record: ScanRecord) throws {
        context.insert(record)
        try save()
    }

    func addGenerated(_ record: GeneratedRecord) throws {
        context.insert(record)
        try save()
    }

    func deleteScan(_ record: ScanRecord) throws {
        context.delete(record)
        try save()
    }

    func deleteGenerated(_ record: GeneratedRecord) throws {
        context.delete(record)
        try save()
    }

    func clearAll() throws {
        try context.delete(model: ScanRecord.self)
        try context.delete(model: GeneratedRecord.self)
        try save()
    }

    func applyRetention(_ retention: HistoryRetention, now: Date) throws {
        guard let cutoff = retention.cutoffDate(now: now) else {
            return
        }

        try context.delete(
            model: ScanRecord.self,
            where: #Predicate<ScanRecord> { record in
                record.createdAt < cutoff
            }
        )
        try context.delete(
            model: GeneratedRecord.self,
            where: #Predicate<GeneratedRecord> { record in
                record.createdAt < cutoff
            }
        )
        try save()
    }

    private func save() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw HistoryRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }
}
