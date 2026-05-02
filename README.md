# 台語辭典

<img src="assets/icon/taigi_dict.png" alt="台語辭典 App Icon" width="120" />

[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&color=success&logo=android)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

[正體中文說明](README.zh-Hant.md)

Offline Taiwanese Hokkien and Mandarin dictionary project built around the
Ministry of Education dataset.

This repository currently contains two app implementations that share the same
product scope:

- Flutter app at the repository root for Android and legacy cross-platform code
- Native Swift / SwiftUI app in `ios-native/` for current iOS development

Both apps focus on offline lookup, downloadable audio archives, bookmarks,
localized UI, and reference material for Tailo and Hanji usage.

## Project Status

- Android: maintained from the Flutter project in the repository root
- iOS: maintained from `ios-native/` with `TaigiDictNative.xcworkspace`
- Legacy Flutter iOS host: still present in `ios/` during migration, but not the primary iOS app target

## Core Experience

The product is organized around three primary tabs:

- `Dictionary`: search Taiwanese headwords, Tailo romanization, and Mandarin definitions; reopen recent searches; drill into a dedicated detail page
- `Bookmarks`: save entries and reopen them later
- `Settings`: manage offline resources, appearance, language, reference material, and app information

## App Identity

- Dart package name: `taigi_dict`
- App display name: `台語辭典`
- Android application ID: `org.taigidict.app`
- iOS bundle identifier: `org.taigidict.app`
- Current Flutter app version: `1.3.0+3`
- Official project domain: `https://taigidict.org`
- Production asset host: `https://app.taigidict.org/assets/`

## Features

- Search Taiwanese headwords, Tailo romanization, and Mandarin definitions with weighted ranking and recent search history
- Open dedicated entry detail pages with linked definitions and native share support
- Save entries to bookmarks and reopen them from a separate tab
- Download ministry word audio and example audio for offline playback
- Offer Traditional Chinese, Simplified Chinese, and English UI
- Adjust theme and reading text size
- Read built-in Tailo and Hanji reference pages plus about and license screens

## Data And Licensing

Canonical ministry references:

- Dictionary reference: `https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/`
- Copyright and licensing note: `https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
- Source spreadsheet: `https://sutian.moe.edu.tw/media/senn/ods/kautian.ods`
- Tailo guide: `https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/`
- Hanji usage guide: `https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/`

Production offline resource endpoints used by the apps:

- Dictionary audio archive: `https://app.taigidict.org/assets/sutiau-mp3.zip`
- Example audio archive: `https://app.taigidict.org/assets/leku-mp3.zip`
- Raw dictionary source: `https://app.taigidict.org/assets/kautian.ods`

Important distribution note:

- The upstream raw data is under `CC BY-ND 3.0 TW`
- Android Flutter app bundles the raw `kautian.ods` asset and builds the local SQLite database on-device
- Native iOS app uses the generated dictionary package under `ios-native/Generated/Dictionary/` and does not parse `kautian.ods` at runtime

## Tech Stack

Flutter / Android implementation:

- Flutter with Material 3
- `dio` for resumable downloads
- `just_audio` for offline audio playback
- `flutter_open_chinese_convert` for runtime OpenCC conversion
- `shared_preferences` for settings, bookmarks, and recent searches
- `spreadsheet_decoder` for parsing `kautian.ods`
- `sqflite` for the local SQLite dictionary database

Native iOS implementation:

- SwiftUI
- `GRDB.swift` for SQLite access
- `SwiftyOpenCC` for Chinese conversion
- `ZIPFoundation` for offline archive handling

## Project Structure

- `lib/`: Flutter application code
- `android/`: Flutter Android host project
- `ios/`: legacy Flutter iOS host kept during migration
- `ios-native/`: native Swift / SwiftUI iOS app, local Swift package, and tests
- `ios-native/Generated/Dictionary/`: generated dictionary assets for the native iOS app
- `assets/dictionary/kautian.ods`: bundled raw dictionary source used by the Flutter app
- `tool/build_dictionary_asset.py`: reference conversion script for the Flutter-side ODS mapping

## Run

Android Flutter app:

```bash
flutter pub get
flutter run -d android
```

Native iOS app:

- Open `ios-native/TaigiDictNative.xcworkspace` in Xcode
- Select the `TaigiDictNative` scheme
- Build and run on an iOS 17 simulator or device

For more native iOS details, see [`ios-native/README.md`](ios-native/README.md).

## Verify

Flutter project:

```bash
flutter analyze
flutter test
```

Native iOS package and shared logic:

```bash
swift test --package-path ios-native
```

## Development Notes

- Active iOS product work happens in `ios-native/`
- The legacy Flutter iOS host in `ios/` is still checked in for migration compatibility
- `pubspec.yaml` pins `path_provider_foundation` with `dependency_overrides` to `2.6.0`
- `spreadsheet_decoder` is a git dependency, so Flutter dependency resolution is not fully pub.dev-only

## Build Release APK

```bash
flutter build apk --release
```

Generated artifact:

- `build/app/outputs/flutter-apk/app-release.apk`

## Privacy Policy

- Bilingual English / Traditional Chinese: `PRIVACY_POLICY.md`

## Acknowledgments

- Ministry of Education Taiwanese Hokkien Dictionary: `https://sutian.moe.edu.tw/`
- Tauhu-oo 20.05 font for Taiwanese Hanzi and specific CJK Extension glyph coverage: `https://github.com/tauhu-tw/tauhu-oo`
- jf open-huninn font used in the app icon artwork: `https://github.com/justfont/open-huninn-font`
- Open Chinese Convert for Flutter for runtime OpenCC conversion: `https://github.com/zonble/flutter_open_chinese_convert`
- GRDB.swift: `https://github.com/groue/GRDB.swift`
- ZIPFoundation: `https://github.com/weichsel/ZIPFoundation`
- SwiftyOpenCC: `https://github.com/PhoenixEmik/SwiftyOpenCC`

## License

- App code: MIT. See `LICENSE`.
- Dictionary data: `CC BY-ND 3.0 TW`. See `DATA_LICENSE.md`.
- Dictionary audio: `CC BY-ND 3.0 TW`. See `DATA_LICENSE.md`.
- Ministry copyright note: `https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
