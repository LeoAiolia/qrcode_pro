import SwiftUI

// 基线已升至 iOS 16 / macOS 13，scrollContentBackground 不再需要 #available 包装。
extension View {
    func hideScrollBackgroundWhenAvailable() -> some View {
        scrollContentBackground(.hidden)
    }
}
