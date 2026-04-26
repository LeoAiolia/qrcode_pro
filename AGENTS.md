# Repository Guidelines

## Project Structure & Module Organization

This is a SwiftUI multiplatform QR scanning and generation app. The Xcode project is `QRScan Pro.xcodeproj`, with schemes `QRScan Pro iOS` and `QRScan Pro Mac`.

- `QRScanPro/iOS/`: iOS-only app entry, camera scanning, sharing, haptics, clipboard, and photo-library integration.
- `QRScanPro/macOS/`: macOS-only app entry, root view, and desktop clipboard behavior.
- `QRScanPro/Shared/Models/`: SwiftData models and value types such as scan, history, barcode, and generation config records.
- `QRScanPro/Shared/Services/`: QR generation, recognition, persistence, export, settings, platform capability, and logging services.
- `QRScanPro/Shared/Features/`: user-facing scanner, generator, history, settings, web, and debug views.
- `QRScanPro/Shared/UI/`: design tokens, reusable UI helpers, compatibility shims, and shared presentation components.
- `design/`: product/design references. Do not treat these as compiled source.

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
