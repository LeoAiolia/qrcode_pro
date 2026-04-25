# QRScan Pro

SwiftUI 多平台扫码与二维码生成应用。

## 工程

- Xcode 工程：`QRScan Pro.xcodeproj`
- iOS / iPadOS scheme：`QRScan Pro iOS`
- macOS scheme：`QRScan Pro Mac`
- Bundle ID：`com.yuxiaor.qrscnpro`
- iOS 最低版本：iOS 15.0
- macOS 最低版本：macOS 12.0

## 平台能力

- iOS / iPadOS：相机实时扫码、图片识别、二维码生成、历史记录、设置、`SFSafariViewController` 内置网页打开。
- macOS：图片二维码识别、二维码生成、历史记录、设置；网页链接使用系统默认浏览器打开。
- 不支持的能力通过 `PlatformCapability` 统一判断并隐藏或降级。

## 调试日志

Debug 构建下，设置页会显示“调试日志”入口。日志同时写入 `OSLog` 和应用内日志列表，便于定位扫码、识别、生成和存储问题。

## 验证命令

```sh
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro iOS" -configuration Debug -sdk iphonesimulator -derivedDataPath /tmp/QRScanProDerivedData-iOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -project "QRScan Pro.xcodeproj" -scheme "QRScan Pro Mac" -configuration Debug -derivedDataPath /tmp/QRScanProDerivedData CODE_SIGNING_ALLOWED=NO build
```
