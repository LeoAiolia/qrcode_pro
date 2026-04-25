# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概览

SwiftUI 多平台扫码与二维码生成应用。
- Bundle ID：`com.yuxiaor.qrscnpro`
- iOS 最低版本：iOS 15.0 / macOS 最低版本：macOS 12.0
- Scheme：`QRScan Pro iOS`（iOS/iPadOS）、`QRScan Pro Mac`（macOS）

## 构建与验证

```sh
# iOS 模拟器构建
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro iOS" -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/QRScanProDerivedData-iOS CODE_SIGNING_ALLOWED=NO build

# macOS 构建
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro Mac" -configuration Debug -derivedDataPath /tmp/QRScanProDerivedData CODE_SIGNING_ALLOWED=NO build
```

## 架构

```
QRScanPro/
├── iOS/          # iOS 专属实现（相机、分享、剪贴板、SafariPresenter）
├── macOS/        # macOS 专属实现（剪贴板、分享、图片导入）
└── Shared/
    ├── Models/   # 纯数据结构：BarcodeKind、ScanResult、AppSettings、AppTab
    ├── Services/ # 业务服务：AppStore、LocalStorage、QRCodeGenerator、BarcodeImageRecognizer、PlatformCapability、DebugLogger
    ├── Features/ # 各 Tab 页面：Scanner、Generator、History、Settings、Debug
    └── UI/       # 通用 UI：RootView、Theme、PlatformImageView、Compatibility
```

**状态管理**：`AppStore`（`@MainActor ObservableObject`）是唯一全局状态容器，通过 `@EnvironmentObject` 注入所有视图。历史记录和设置均由 `AppStore` 统一读写，底层持久化走 `LocalStorage`。

**平台差异**：
- 用 `#if os(iOS)` / `#if os(macOS)` 隔离平台专属代码
- 运行时能力判断统一走 `PlatformCapability`（相机、手电筒、应用内浏览器等）
- iOS 的生成器以 `.sheet` 弹出；macOS 直接作为独立 Tab

**主题**：所有颜色和样式从 `AppTheme`（`Shared/UI/Theme.swift`）取值，禁止在视图中硬编码颜色。卡片背景使用 `.cardBackground()` 扩展。

**调试日志**：`DebugLogger` 同时写入 `OSLog` 和应用内日志列表；Debug 构建下设置页显示"调试日志"入口（`DebugLogView`）。
