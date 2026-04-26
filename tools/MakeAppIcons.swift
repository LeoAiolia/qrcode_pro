#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

// 渲染 QRScan Pro 的 AppIcon。基于 design/qrscan_pro_assets.html 的 SVG 几何。
// viewBox 100×100，放大到任意输出尺寸；finder pattern + data modules。

struct ColorRGBA {
    let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
    static let black = ColorRGBA(r: 0, g: 0, b: 0, a: 1)
    static let white = ColorRGBA(r: 1, g: 1, b: 1, a: 1)
    static let blueLight = ColorRGBA(r: 0x00 / 255.0, g: 0x7A / 255.0, b: 0xFF / 255.0, a: 1) // #007AFF
    static let blueDark  = ColorRGBA(r: 0x0A / 255.0, g: 0x84 / 255.0, b: 0xFF / 255.0, a: 1) // #0A84FF
    static let clear = ColorRGBA(r: 0, g: 0, b: 0, a: 0)
}

enum Variant { case light, dark, tinted, mac }

// 数据模块矩形（来自设计稿；6×6 模块在 viewBox 100×100 下）
let dataModules: [(CGFloat, CGFloat)] = [
    (42, 6), (52, 6),
    (42, 16),
    (42, 26), (52, 26),
    (6, 42), (16, 42), (32, 42), (42, 42), (62, 42), (78, 42), (88, 42),
    (42, 52), (62, 52), (72, 52), (82, 52),
    (42, 62), (52, 62), (78, 62),
    (42, 72), (62, 72), (72, 72), (88, 72),
    (42, 82), (52, 82), (68, 82), (78, 82), (88, 82),
]

// 三个 finder pattern 的左上角
let finderOrigins: [(CGFloat, CGFloat)] = [(6, 6), (66, 6), (6, 66)]

func setFill(_ ctx: CGContext, _ c: ColorRGBA) {
    ctx.setFillColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
}

func roundedRect(_ ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) {
    let path = CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h),
                      cornerWidth: r, cornerHeight: r, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
}

func drawIcon(size: CGFloat, variant: Variant) -> CGImage {
    let bytesPerPixel = 4
    let intSize = Int(size)
    let bytesPerRow = bytesPerPixel * intSize
    let cs = CGColorSpaceCreateDeviceRGB()
    let info: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(data: nil, width: intSize, height: intSize,
                              bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                              space: cs, bitmapInfo: info) else {
        fatalError("无法创建位图上下文")
    }
    // 翻转坐标使 (0,0) 在左上（与 SVG 一致）
    ctx.translateBy(x: 0, y: size)
    ctx.scaleBy(x: 1, y: -1)

    let scale = size / 100.0

    // 背景
    let bg: ColorRGBA
    switch variant {
    case .light: bg = ColorRGBA(r: 0xF7 / 255.0, g: 0xF8 / 255.0, b: 0xFA / 255.0, a: 1) // 浅灰白
    case .dark:  bg = ColorRGBA(r: 0x10 / 255.0, g: 0x12 / 255.0, b: 0x18 / 255.0, a: 1) // 深背景
    case .tinted: bg = .clear // 透明，由系统着色
    case .mac:   bg = .white
    }
    if variant != .tinted {
        setFill(ctx, bg)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }

    // 颜色方案
    let outer: ColorRGBA
    let accent: ColorRGBA
    let innerHole: ColorRGBA
    let module: ColorRGBA
    switch variant {
    case .light:
        outer = .black
        accent = .blueLight
        innerHole = .white
        module = .black
    case .dark:
        outer = .white
        accent = .blueDark
        innerHole = ColorRGBA(r: 0x10 / 255.0, g: 0x12 / 255.0, b: 0x18 / 255.0, a: 1)
        module = .white
    case .tinted:
        // 单色：用白色绘制全部前景，由系统着色
        outer = .white
        accent = .white
        innerHole = ColorRGBA(r: 0, g: 0, b: 0, a: 0)
        module = .white
    case .mac:
        outer = .black
        accent = .blueDark
        innerHole = .white
        module = .black
    }

    // 三个 finder pattern
    for (fx, fy) in finderOrigins {
        // 外框
        setFill(ctx, outer)
        roundedRect(ctx, x: fx * scale, y: fy * scale, w: 28 * scale, h: 28 * scale, r: 3 * scale)
        // 中环（蓝色）
        setFill(ctx, accent)
        roundedRect(ctx, x: (fx + 5) * scale, y: (fy + 5) * scale, w: 18 * scale, h: 18 * scale, r: 2 * scale)
        // 内孔
        if variant == .tinted {
            // 在白色 finder pattern 上"挖"出透明孔，用 clear blend
            ctx.saveGState()
            ctx.setBlendMode(.clear)
            roundedRect(ctx, x: (fx + 9) * scale, y: (fy + 9) * scale, w: 10 * scale, h: 10 * scale, r: 1 * scale)
            ctx.restoreGState()
        } else {
            setFill(ctx, innerHole)
            roundedRect(ctx, x: (fx + 9) * scale, y: (fy + 9) * scale, w: 10 * scale, h: 10 * scale, r: 1 * scale)
        }
    }

    // 数据模块
    setFill(ctx, module)
    for (mx, my) in dataModules {
        roundedRect(ctx, x: mx * scale, y: my * scale, w: 6 * scale, h: 6 * scale, r: 1 * scale)
    }

    return ctx.makeImage()!
}

func savePNG(_ image: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG 编码失败：\(url.path)")
    }
    try! data.write(to: url)
    print("写入 \(url.path)")
}

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iosDir = projectRoot.appendingPathComponent("QRScanPro/iOS/Assets.xcassets/AppIcon.appiconset")
let macDir = projectRoot.appendingPathComponent("QRScanPro/macOS/Assets.xcassets/AppIcon.appiconset")
let launchDir = projectRoot.appendingPathComponent("QRScanPro/iOS/Assets.xcassets/LaunchLogo.imageset")

// iOS：单尺寸 1024 + 三种外观
savePNG(drawIcon(size: 1024, variant: .light),
        to: iosDir.appendingPathComponent("AppIcon-1024.png"))
savePNG(drawIcon(size: 1024, variant: .dark),
        to: iosDir.appendingPathComponent("AppIcon-1024-Dark.png"))
savePNG(drawIcon(size: 1024, variant: .tinted),
        to: iosDir.appendingPathComponent("AppIcon-1024-Tinted.png"))

// macOS：所有需要的尺寸（asset catalog 不接受单尺寸 macOS icon）
let macSizes: [(Int, Int, String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png"),
]
for (pt, scale, name) in macSizes {
    let px = CGFloat(pt * scale)
    savePNG(drawIcon(size: px, variant: .mac), to: macDir.appendingPathComponent(name))
}

// 启动屏图标（透明 tinted 变体在浅/深背景上都好看）
savePNG(drawIcon(size: 240, variant: .light),  to: launchDir.appendingPathComponent("LaunchLogo.png"))
savePNG(drawIcon(size: 480, variant: .light),  to: launchDir.appendingPathComponent("LaunchLogo@2x.png"))
savePNG(drawIcon(size: 720, variant: .light),  to: launchDir.appendingPathComponent("LaunchLogo@3x.png"))

print("完成")
