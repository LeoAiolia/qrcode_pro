import Foundation
import SwiftData

@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var value: String
    var kind: BarcodeKind
    var source: ScanSource
    var createdAt: Date

    init(
        id: UUID = UUID(),
        value: String,
        kind: BarcodeKind,
        source: ScanSource,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.value = value
        self.kind = kind
        self.source = source
        self.createdAt = createdAt
    }

    var url: URL? {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        switch scheme {
        case "http", "https":
            return url
        default:
            return nil
        }
    }
}
