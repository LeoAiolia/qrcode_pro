import SafariServices
import SwiftUI
import UIKit

enum SafariPresenter {
    static func present(url: URL) {
        guard let controller = topViewController() else {
            UIApplication.shared.open(url)
            return
        }

        let safariController = SFSafariViewController(url: url)
        controller.present(safariController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { scene in
                switch scene.activationState {
                case .foregroundActive:
                    return true
                case .unattached, .foregroundInactive, .background:
                    return false
                @unknown default:
                    return false
                }
            }

        guard let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
