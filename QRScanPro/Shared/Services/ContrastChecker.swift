import Foundation

/// WCAG 2.0 相对亮度对比度计算；用于警告"前后景对比度过低"的场景。
enum ContrastChecker {
    static func ratio(foregroundHex: String, backgroundHex: String) -> Double {
        let fg = HexColor(hex: foregroundHex) ?? HexColor(red: 0, green: 0, blue: 0)
        let bg = HexColor(hex: backgroundHex) ?? HexColor(red: 1, green: 1, blue: 1)
        return ratio(foreground: fg, background: bg)
    }

    static func ratio(foreground: HexColor, background: HexColor) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ color: HexColor) -> Double {
        func channel(_ value: Double) -> Double {
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red)
            + 0.7152 * channel(color.green)
            + 0.0722 * channel(color.blue)
    }
}
