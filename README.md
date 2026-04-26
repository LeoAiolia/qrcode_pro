# QRScan Pro

SwiftUI 多平台扫码与二维码生成应用。

## 工程

- Xcode 工程：`QRScan Pro.xcodeproj`
- iOS / iPadOS scheme：`QRScan Pro iOS`
- macOS scheme：`QRScan Pro Mac`
- Bundle ID：`com.yuxiaor.qrscnpro`
- iOS 最低版本：iOS 17.0（SwiftData / @Observable 要求）
- macOS 最低版本：macOS 14.0

## 平台能力

- iOS / iPadOS：相机实时扫码、闪光灯、相册多码识别、连续扫码、内置 WebView 打开 URL、二维码生成（颜色 / 形状 / Logo / margin / 多格式导出）、历史记录、设置。
- macOS：拖拽 / `NSOpenPanel` 多张图片批量识别、CSV 导出、二维码生成（同 iOS 全参数）、PNG / SVG / PDF 导出、默认导出目录（安全 bookmark）、历史与设置。
- 平台差异通过 `PlatformCapability` + `#if os(...)` 隔离。

## 架构分层

```
View (SwiftUI)
  └── ViewState / @Observable 编排
        └── Repository（HistoryRepository 协议 + SwiftData 实现）
              └── Service（CoreImage / Vision / AVFoundation / Exporters）
```

- `SettingsStore`（@Observable + UserDefaults）：用户偏好。
- `HistoryRepository`（协议 + `SwiftDataHistoryRepository` + `InMemoryHistoryRepository`）：扫码 / 生成历史，含过期清理。
- `QRCodeGenerator` / `LogoCompositor` / `DotShapeRenderer` / `ContrastChecker`：生成链。
- `Exporters/`：`PNGExporter`、`SVGExporter`、`PDFExporter`，统一通过 `FileExporter` 落盘。
- 视图禁止直连 Service / 持久化，统一通过状态层调用。

## 目录结构

```
QRScanPro/
├── iOS/                         # iOS 专属：相机、Haptic、PHPicker、ShareSheet
│   ├── Assets.xcassets/         # AppIcon（光/暗/Tinted 变体）+ AccentColor + LaunchLogo
│   └── PrivacyInfo.xcprivacy
├── macOS/                       # macOS 专属：剪贴板、入口
│   ├── Assets.xcassets/         # AppIcon 全尺寸 + AccentColor
│   ├── PrivacyInfo.xcprivacy
│   └── QRScanProMac.entitlements # sandbox + camera + 用户文件读写 + bookmark
└── Shared/
    ├── Models/                  # @Model ScanRecord / GeneratedRecord，GenerateConfig
    ├── Services/                # 业务服务 + Exporters/
    ├── Features/                # Scanner / History / Generator / Settings / Web / Debug
    └── UI/                      # Theme / DesignTokens / Compatibility 等
```

## 资源

- AppIcon、AccentColor、启动占位 PNG 由 `tools/MakeAppIcons.swift` 基于 `design/qrscan_pro_assets.html` 的 SVG 几何渲染。
- 重新生成命令：

```sh
xcrun swiftc tools/MakeAppIcons.swift -o /tmp/make_app_icons && /tmp/make_app_icons
```

- iOS AppIcon 含 light / dark / tinted 三个 1024×1024 变体；macOS 提供 16 → 1024 全尺寸。
- 启动屏由 `INFOPLIST_KEY_UILaunchScreen_ImageName = LaunchLogo` 配合 `INFOPLIST_KEY_UILaunchScreen_Generation = YES` 自动合成，无需 storyboard。

## 隐私 / 权限

- iOS：`Info.plist` 文案（相机 / 相册 / 写入相册）通过 `INFOPLIST_KEY_*` 注入；`PrivacyInfo.xcprivacy` 声明 UserDefaults / FileTimestamp / DiskSpace 三类必需 API 用途。
- macOS：sandbox 开启；entitlement 含 camera / `files.user-selected.read-write` / `files.bookmarks.app-scope`，与"默认导出目录"安全 bookmark 协同。

## 调试日志

Debug 构建下，设置页会显示"调试日志"入口。日志同时写入 `OSLog` 与应用内日志列表，便于定位扫码、识别、生成和存储问题。

## 验证命令

```sh
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro iOS" \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath /tmp/QRScanProDerivedData-iOS CODE_SIGNING_ALLOWED=NO build

xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro Mac" \
  -configuration Debug \
  -derivedDataPath /tmp/QRScanProDerivedData CODE_SIGNING_ALLOWED=NO build
```

## 已知 TODO（v1.0 之后）

- iCloud 同步与跨设备历史合并。
- 商业化订阅 / 高级生成模板。
- Mac Catalyst 形态选型评估。
- VoiceOver 主路径完整 5 条录屏走查（人工任务）。
- 真机 Archive 预演（需登录开发者账号）。
