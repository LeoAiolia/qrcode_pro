import UIKit

enum ClipboardService {
    static func copy(_ value: String) {
        UIPasteboard.general.string = value
    }
}
