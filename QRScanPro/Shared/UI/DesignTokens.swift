import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum Radius {
    static let xs: CGFloat = 4
    static let s: CGFloat = 6
    static let m: CGFloat = 8
    static let l: CGFloat = 10
    static let xl: CGFloat = 14
    static let pill: CGFloat = 999
}

enum AppFont {
    static let largeTitle: Font = .system(size: 34, weight: .bold)
    static let title: Font = .system(size: 22, weight: .semibold)
    static let headline: Font = .system(size: 17, weight: .semibold)
    static let body: Font = .system(size: 15, weight: .regular)
    static let footnote: Font = .system(size: 13, weight: .regular)
    static let caption: Font = .system(size: 12, weight: .regular)
    static let mono: Font = .system(size: 14, weight: .regular, design: .monospaced)
}

enum AppColor {
    // 背景三层：页面用 grouped 底色，item/card 用更高层级的 surface。
    static var background: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var surface: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }

    static var surfaceRaised: Color {
        #if os(iOS)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    // 文字三层
    static var textPrimary: Color {
        #if os(iOS)
        return Color(uiColor: .label)
        #elseif os(macOS)
        return Color(nsColor: .labelColor)
        #endif
    }

    static var textSecondary: Color {
        #if os(iOS)
        return Color(uiColor: .secondaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .secondaryLabelColor)
        #endif
    }

    static var textTertiary: Color {
        #if os(iOS)
        return Color(uiColor: .tertiaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .tertiaryLabelColor)
        #endif
    }

    // 分隔
    static var separator: Color {
        #if os(iOS)
        return Color(uiColor: .separator)
        #elseif os(macOS)
        return Color(nsColor: .separatorColor)
        #endif
    }

    // 语义色（HIG system colors，跨平台同名）
    static let accent = Color.accentColor
    static let info = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
}
