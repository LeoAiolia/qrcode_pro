import Foundation

enum BarcodeKind: String, Codable, CaseIterable, Identifiable {
    case qr
    case ean13
    case ean8
    case upce
    case code128
    case code39
    case pdf417
    case aztec
    case dataMatrix
    case unknown

    var id: String { rawValue }

    static var configurableKinds: [BarcodeKind] {
        allCases.filter { kind in
            switch kind {
            case .unknown:
                return false
            case .qr, .ean13, .ean8, .upce, .code128, .code39, .pdf417, .aztec, .dataMatrix:
                return true
            }
        }
    }

    var displayName: String {
        switch self {
        case .qr:
            return "QR Code"
        case .ean13:
            return "EAN-13"
        case .ean8:
            return "EAN-8"
        case .upce:
            return "UPC-E"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .pdf417:
            return "PDF417"
        case .aztec:
            return "Aztec"
        case .dataMatrix:
            return "Data Matrix"
        case .unknown:
            return "未知码制"
        }
    }
}

enum ScanSource: String, Codable {
    case camera
    case image
    case generated

    var displayName: String {
        switch self {
        case .camera:
            return "相机"
        case .image:
            return "图片"
        case .generated:
            return "生成"
        }
    }
}

struct ScanResult: Identifiable, Codable, Hashable {
    let id: UUID
    let value: String
    let kind: BarcodeKind
    let source: ScanSource
    let createdAt: Date

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

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case qr
    case barcode
    case image
    case generated
    case today

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .qr:
            return "二维码"
        case .barcode:
            return "条形码"
        case .image:
            return "图片"
        case .generated:
            return "生成"
        case .today:
            return "今天"
        }
    }
}
