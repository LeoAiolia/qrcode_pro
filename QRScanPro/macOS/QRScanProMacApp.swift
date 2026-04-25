import SwiftUI

@main
struct QRScanProMacApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 860, minHeight: 620)
        }
    }
}
