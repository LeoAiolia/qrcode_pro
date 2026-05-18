import SwiftUI

// 旧名称保留为门面，全部转发到 DesignTokens，方便逐步迁移。
enum AppTheme {
    static var accent: Color { AppColor.accent }
    static var background: Color { AppColor.background }
    static var surface: Color { AppColor.surface }
    static var surfaceRaised: Color { AppColor.surfaceRaised }
    static var textSecondary: Color { AppColor.textSecondary }
    static var warning: Color { AppColor.warning }
    static var danger: Color { AppColor.danger }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColor.surface)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
