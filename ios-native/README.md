# Taigi Dict Apple Native

This directory contains the native Swift / SwiftUI Apple-platform version of Taigi Dict.

The app is built as a small Xcode application target on top of a local Swift
package:

- `TaigiDictCore`: dictionary loading, search, bookmarks, offline audio,
  preferences, and OpenCC-backed conversion.
- `TaigiDictUI`: SwiftUI screens for dictionary search, detail, bookmarks,
  settings, licenses, and reference articles.
- `NativeApp`: the production app entry point and asset catalog.
- `Generated/Dictionary`: bundled dictionary manifest and JSONL entry package.

## Current App Scope

The native Apple app currently includes:

- dictionary search with native `NavigationStack` / `NavigationSplitView`
- entry detail pages with linked references, bookmarks, share, and audio actions
- bookmarks with native swipe actions
- settings for interface language, theme, reading text size, offline audio, and advanced maintenance
- initialization and maintenance flows that can restore bundled dictionary source, download source data, and rebuild installed dictionary data
- bundled reference articles plus about, privacy, license, and third-party license screens
- simplified/traditional conversion through `SwiftyOpenCC`

## Requirements

- Xcode 17 or newer
- iOS 17 simulator or device target
- macOS 14 or newer local runtime target

## Build And Run

Open the workspace, not just the project:

```bash
open TaigiDictNative.xcworkspace
```

Then select:

- `TaigiDictNative` for iPhone or iPad
- `TaigiDictNativeMac` for macOS

Command-line iOS build:

```bash
xcodebuild \
  -workspace TaigiDictNative.xcworkspace \
  -scheme TaigiDictNative \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Command-line macOS build:

```bash
xcodebuild \
  -workspace TaigiDictNative.xcworkspace \
  -scheme TaigiDictNativeMac \
  -destination 'platform=macOS' \
  build
```

One-step macOS verification:

```bash
./Scripts/verify_macos.sh
```

## Package Layout

```text
ios-native/
  TaigiDictNative.xcworkspace
  TaigiDictNative.xcodeproj
  Package.swift
  Generated/
    Dictionary/
  NativeApp/
  NativeAppUITests/
  Sources/
    TaigiDictCore/
    TaigiDictUI/
  Tests/
  Scripts/
  docs/
```

Notable source areas:

- `Sources/TaigiDictCore/Conversion`
  OpenCC-backed text conversion services
- `Sources/TaigiDictCore/Data`
  dictionary import/loading, installed storage, source resources, bookmarks, and offline audio
- `Sources/TaigiDictUI/Dictionary`
  search, result rows, and detail screens
- `Sources/TaigiDictUI/Initialization`
  first-run preparation and readiness flow
- `Sources/TaigiDictUI/Settings`
  settings, advanced maintenance, dictionary source controls, and offline audio management
- `Sources/TaigiDictUI/Info`
  about, licenses, and reference article screens

## Dependencies

Current package dependencies:

- `SwiftyOpenCC` `1.4.2`
- `GRDB.swift` `7.10.0`
- `ZIPFoundation` `0.9.20`

## Data Boundaries

- Native Swift code lives under `ios-native/`.
- The app bundles generated dictionary resources under `Generated/Dictionary/` for both iOS and macOS.
- The app does not parse `kautian.ods` at runtime.
- Dictionary source material must be converted before runtime into app-readable packaged resources.
- The production app loads bundled dictionary resources and can also use installed resources from Application Support.
- The app can restore bundled source resources or download source resources into local storage for rebuilds.

The native app entry point is `NativeApp/TaigiDictNativeApp.swift`.

## Testing

Command-line package tests:

```bash
swift test
```

iOS build verification:

```bash
xcodebuild \
  -workspace TaigiDictNative.xcworkspace \
  -scheme TaigiDictNative \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

macOS build verification:

```bash
xcodebuild \
  -workspace TaigiDictNative.xcworkspace \
  -scheme TaigiDictNativeMac \
  -destination 'platform=macOS' \
  build
```

Desktop validation checklist:

- [docs/macos-validation-checklist.md](</Users/emik/repository/taigi-dict/ios-native/docs/macos-validation-checklist.md>)

## Notes

- Use `TaigiDictNative.xcworkspace` so SwiftPM dependencies resolve correctly.
- Chinese conversion should go through the abstraction in
  `ChineseConversionService`, not direct package calls from UI code.
- The app is intentionally using native SwiftUI components rather than a
  cross-platform UI abstraction.
