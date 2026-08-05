# Repository Guidelines

## Project Overview

SwiftUI multiplatform QR scanning and generation app.
- Bundle ID: `com.yuxiaor.qrscnpro`
- Minimum OS: iOS 17.0 / macOS 14.0
- Schemes: `QRScan Pro iOS` (iOS/iPadOS), `QRScan Pro Mac` (macOS)
- Language mode: Swift 5 (Xcode project setting `SWIFT_VERSION = 5.0`)

## Project Structure & Module Organization

- `QRScanPro/iOS/`: iOS-only app entry, camera scanning, sharing, haptics, clipboard, photo-library, and splash.
- `QRScanPro/macOS/`: macOS-only app entry and root sidebar navigation.
- `QRScanPro/Shared/Models/`: SwiftData `@Model` records (`ScanRecord`, `GeneratedRecord`) and pure value types (`BarcodeKind`, `ScanSource`, `GenerateConfig`, `RecognizedCode`).
- `QRScanPro/Shared/Services/`: repositories and settings, QR generation, recognition, exporters, platform capability, and logging.
- `QRScanPro/Shared/Features/`: per-tab views plus `@Observable` state objects (`Scanner`, `Generator`, `History`, `Settings`, `Web`, `Debug`).
- `QRScanPro/Shared/UI/`: design tokens, theme facade, and reusable presentation components.
- `design/`: product/design references. Do not treat these as compiled source.

## Architecture

Layered directory layout; UI stays in `Shared/Features`, business logic in `Shared/Services`, and pure data in `Shared/Models`.

```
QRScanPro/
├── iOS/          # app entry, camera scanner, haptics, photo library, share sheet
├── macOS/        # app entry, image recognition, CSV export
└── Shared/
    ├── Models/   # SwiftData @Model records + pure value types
    ├── Services/ # repositories, settings, generator/recognizer, exporters, logging
    ├── Features/ # views + @Observable state objects
    └── UI/       # design tokens, theme facade, reusable components
```

### State & persistence

- **Settings**: `SettingsStore` (`@MainActor @Observable`, UserDefaults-backed, injected via `.environment(settings)`) is the single source of truth for settings. Every property change persists a full JSON snapshot.
- **History**: two SwiftData `@Model` records — `ScanRecord` and `GeneratedRecord` — served through the injected `.modelContainer`. Reads in views use `@Query`; writes are defined by the `HistoryRepository` protocol (implemented by `SwiftDataHistoryRepository`). Keep write paths going through the repository — views should not reach for `modelContext` directly.
- **Feature state**: `GeneratorState` and `MacImageRecognitionState` (`@Observable`) own per-screen state and async work (debounced generation, batch recognition); views bind to them.
- **Logging**: `DebugLogger.shared` mirrors entries to OSLog and an in-memory list; the Settings tab exposes `DebugLogView` in Debug builds.

### Platform differences

- iOS scans via camera (`ScannerView` + `LiveScannerContainer`, AVCaptureSession) and photo picking; the generator is one of the four tabs; results open in an in-app browser (`InAppBrowserView`).
- macOS has no camera path: `MacImageRecognitionView` handles image drop/selection and CSV export; the generator is a sidebar item and exports PNG / SVG / PDF.
- `#if os(iOS)` / `#if os(macOS)` isolate platform code; runtime capability queries go through `PlatformCapability` (camera, torch, in-app browser, …).

### Theme

All colors and fonts come from `DesignTokens.swift` (`AppColor`, `AppFont`, `Spacing`, `Radius`). `AppTheme` is a legacy facade forwarding to it. Card surfaces use the `.cardBackground()` extension. Never hard-code colors in views.

## Build, Test, and Development Commands

Use Xcode for interactive development, or run these verification builds from the repository root:

```sh
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro iOS" -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/QRScanProDerivedData-iOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro Mac" -configuration Debug -derivedDataPath /tmp/QRScanProDerivedData CODE_SIGNING_ALLOWED=NO build
```

The project targets iOS 17.0 and macOS 14.0, matching the SwiftData requirements in the Xcode configuration.

## Coding Style & Naming Conventions

Follow existing Swift style: 4-space indentation, `PascalCase` for types, `camelCase` for properties/functions, and `// MARK:` sections for larger views. Keep shared logic under `Shared` and isolate platform code with `#if os(iOS)` / `#if os(macOS)`. Use `PlatformCapability` for runtime feature differences. Prefer `AppColor`, `AppFont`, `Spacing`, and `Radius` from `Shared/UI/DesignTokens.swift`; avoid hard-coded colors in views.

## Testing Guidelines

No dedicated test target is currently present. For changes, run both iOS simulator and macOS build commands above. When adding tests later, create XCTest targets in the Xcode project, name files after the unit under test, and use focused names such as `QRCodeGeneratorTests` or `HistoryRepositoryTests`.

## Commit & Pull Request Guidelines

Recent history uses short imperative commits and scoped feature prefixes, for example `feat(M3): ...`, `refactor(M1): ...`, and `Add Xcode workspace contents file`. Keep commits focused and mention the module or milestone when useful.

Pull requests should include a concise summary, affected platform(s), verification commands run, and screenshots or screen recordings for visible UI changes. Link related issues or product notes when applicable.

## Security & Configuration Tips

Do not commit signing identities, provisioning profiles, private keys, or user-specific Xcode data. Keep generated build artifacts and DerivedData outside the repository, preferably under `/tmp` as shown above.

---

# Swift / iOS 平台规则

- 使用 **Swift 6+**，最低支持 **iOS 16+**。
- 遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) 和苹果人机交互指南（HIG）。

## 安全约束（硬规则）

- **禁止强制解包 `!`**（IBOutlet 除外，且必须注释原因）；禁止 `as!` 强转，用 `as?` 配合安全处理。
- 闭包捕获 `self` 必须评估循环引用，默认使用 `[weak self]`；`[unowned self]` 仅限生命周期严格短于 self 的场景。
- UI 更新必须在**主线程**（`@MainActor` / `DispatchQueue.main`）。

## 框架与架构

- **优先使用 SwiftUI**，兼容 UIKit 代码。
- 架构采用 **MVVM**；响应式状态：新代码使用 **Observation（`@Observable`，需 iOS 17+）**，需兼容 iOS 16 时用 `ObservableObject`。**Combine 仅限维护已有代码，新代码不再引入**。
- 异步统一使用 **`async/await`**（Swift Concurrency），新代码禁止裸回调嵌套。
- 自动布局必须正确适配 **SafeArea**；禁止硬编码状态栏 / 底部安全区高度。
- 优先使用带关联值的 `enum` 表达状态（如 `Result` / `LoadState`）。

## 存储

- 敏感信息（Token、密码、证书）存 **Keychain**，禁止存 UserDefaults / 明文文件。
- 轻量非敏感数据用 **UserDefaults**。
- 结构化数据优先 **SwiftData / CoreData**（已有项目）或 **GRDB**（新项目按需选型）。

## 包管理

- 优先 **SPM**（Swift Package Manager）；已有 CocoaPods 工程保持现状，不做无收益迁移。
- 引入第三方依赖前必须评估：维护活跃度、License、包大小、是否与现有依赖冲突。

## Swift 自检清单（追加到通用清单）

- [ ] 是否使用了 `!` 强解 / `as!` 强转
- [ ] 闭包捕获 self 是否处理循环引用（`[weak self]`）
- [ ] 新代码是否误引入 Combine / 裸回调嵌套（应为 `async/await` + Observation）
- [ ] 敏感信息是否走 **Keychain**（不在 UserDefaults / 明文）
- [ ] SafeArea 是否正确适配（无硬编码状态栏高度）
