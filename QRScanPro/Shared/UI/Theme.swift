import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.43, green: 0.91, blue: 0.72)
    static let background = Color(red: 0.05, green: 0.06, blue: 0.07)
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let surfaceRaised = Color(red: 0.14, green: 0.15, blue: 0.17)
    static let textSecondary = Color.white.opacity(0.68)
    static let warning = Color(red: 0.98, green: 0.75, blue: 0.23)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.38)
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
