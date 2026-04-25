import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case scanner
    case generator
    case history
    case settings

    static var availableTabs: [AppTab] {
        #if os(macOS)
        return [.scanner, .generator, .history, .settings]
        #else
        return [.scanner, .history, .settings]
        #endif
    }

    var title: String {
        switch self {
        case .scanner:
            #if os(macOS)
            return "识别"
            #else
            return "扫码"
            #endif
        case .generator:
            return "生成"
        case .history:
            return "历史"
        case .settings:
            return "设置"
        }
    }

    var systemImage: String {
        switch self {
        case .scanner:
            return "qrcode.viewfinder"
        case .generator:
            return "qrcode"
        case .history:
            return "clock"
        case .settings:
            return "gearshape"
        }
    }
}
