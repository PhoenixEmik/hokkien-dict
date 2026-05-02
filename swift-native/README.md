# Taigi Dict Native Swift

This directory contains the native Swift / SwiftUI rewrite of Taigi Dict.

The production iOS app target lives in `TaigiDictNative.xcodeproj`, with shared
Core and UI code provided by the local Swift package.

## Xcode

Open `TaigiDictNative.xcworkspace`, select the `TaigiDictNative` scheme, choose
an iOS simulator, then build and run.

## Boundaries

- Flutter source remains at the repository root during migration.
- Native Swift source lives under `swift-native/`.
- Dictionary source data is not parsed from `kautian.ods` by the app.
- ODS conversion must happen before runtime and produce JSONL/CSV or SQLite.
- Simplified/traditional conversion must go through SwiftyOpenCC behind
  `ChineseConversionService`.

## Package

```text
swift-native/
  TaigiDictNative.xcworkspace
  TaigiDictNative.xcodeproj
  Package.swift
  Sources/TaigiDictCore/
  Sources/TaigiDictUI/
  NativeApp/
  Tests/TaigiDictCoreTests/
  Tests/TaigiDictUITests/
```

The package exposes `TaigiDictCore` and `TaigiDictUI` for the native app target
and tests.
