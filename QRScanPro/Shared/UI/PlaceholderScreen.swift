import SwiftUI

/// M1 阶段所有未实现 Feature 的统一占位；M2/M3/M4 完成后逐个替换。
struct PlaceholderScreen: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppColor.accent)

            Text(title)
                .font(AppFont.title)
                .foregroundColor(AppColor.textPrimary)

            Text(subtitle)
                .font(AppFont.body)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
    }
}
