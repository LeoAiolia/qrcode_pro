import CoreSpotlight
import SwiftUI
import UniformTypeIdentifiers

/// 把「扫一扫 / 生成二维码」以自定义关键词索引进系统 Spotlight，
/// 让 sao、qr、qrcode 这类拼音/英文缩写也能搜到本 app。
/// 点按搜索结果会以 CSSearchableItemActionType 的 NSUserActivity 唤起 app，
/// 由 iOSRootView 继续并跳转到对应页面。
enum SpotlightIndexer {
    private static let domain = "com.pz.qrscanpro.spotlight"
    private static let scannerIdentifier = "\(domain).scanner"
    private static let generatorIdentifier = "\(domain).generator"

    /// 从搜索结果的 item 标识解析跳转目标；非本 app 的结果返回 nil。
    static func destination(forIdentifier identifier: String) -> AppRouteDestination? {
        switch identifier {
        case scannerIdentifier:
            return .scanner
        case generatorIdentifier:
            return .generator
        default:
            return nil
        }
    }

    /// 每次启动重新建立索引（同 identifier 覆盖写，幂等）。
    static func indexAll() {
        let items = [scannerItem(), generatorItem()]
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                DebugLogger.shared.warning("Spotlight 索引失败：\(error.localizedDescription)")
            }
        }
    }

    private static func scannerItem() -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = "扫一扫"
        attributes.contentDescription = "QRScan Pro · 扫码 / Scan QR Code"
        attributes.keywords = ["扫", "sao", "saoyisao", "sys", "扫一扫", "扫码", "扫描", "扫码器", "scan", "scanning"]
        return CSSearchableItem(
            uniqueIdentifier: scannerIdentifier,
            domainIdentifier: domain,
            attributeSet: attributes
        )
    }

    private static func generatorItem() -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = "生成二维码"
        attributes.contentDescription = "QRScan Pro · 生成二维码 / Generate QR Code"
        attributes.keywords = ["qr", "qrcode", "qr code", "二维码", "生成二维码", "erweima", "generate"]
        return CSSearchableItem(
            uniqueIdentifier: generatorIdentifier,
            domainIdentifier: domain,
            attributeSet: attributes
        )
    }
}
