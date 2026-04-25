import SwiftUI

extension View {
    @ViewBuilder
    func hideScrollBackgroundWhenAvailable() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
