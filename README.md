# 台語辭典

<img src="assets/icon/taigi_dict.png" alt="台語辭典 App Icon" width="120" />

[![Download APK](https://img.shields.io/github/v/release/PhoenixEmik/taigi-dict?label=Download%20APK&color=success&logo=android)](https://github.com/PhoenixEmik/taigi-dict/releases/latest)

[正體中文說明](README.zh-Hant.md)

Flutter dictionary app for Taiwanese Hokkien and Mandarin on Android and iOS.
The app is built around the Ministry of Education dataset, supports offline
lookup, and downloads large offline resources directly to the user's device.

## Overview

The app is organized around three primary tabs:

- `Dictionary`: search Taiwanese headwords, Tailo romanization, and Mandarin definitions; reuse recent searches; open a dedicated detail page for each entry
- `Bookmarks`: keep saved entries in a separate list and reopen them with the same localized detail view
- `Settings`: manage offline resources, appearance, language, reference material, and app information

The first-run experience is also part of the product flow. The app can
download the ministry ODS source, build a local SQLite dictionary on-device,
and then use that database for subsequent offline lookup.

## App Identity

- Dart package name: `taigi_dict`
- App display name: `台語辭典`
- Android application ID: `org.taigidict.app`
- iOS bundle identifier: `org.taigidict.app`
- Official project domain: `https://taigidict.org`
- Production asset host: `https://app.taigidict.org/assets/`

## Features

- Search Taiwanese headwords, Tailo romanization, and Mandarin definitions with weighted ranking and recent search history
- Open dedicated entry detail pages with interactive linked definitions and share support
- Save entries to bookmarks and reopen them from a separate tab
- Download ministry word audio and example audio for offline playback
- Download `kautian.ods` and build the local SQLite dictionary on-device
- Switch UI language, theme, and reading text size
- Read built-in Tailo and Hanji reference pages plus about and license screens
- Use adaptive iOS/Android UI with accessibility-focused semantics and localized tooltips

## Data And Licensing

Canonical ministry references:

- Dictionary reference: `https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/`
- Copyright and licensing note: `https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
- Source spreadsheet: `https://sutian.moe.edu.tw/media/senn/ods/kautian.ods`
- Tailo guide: `https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/`
- Hanji usage guide: `https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/`

Production offline resource endpoints used by the app:

- Dictionary audio archive: `https://app.taigidict.org/assets/sutiau-mp3.zip`
- Example audio archive: `https://app.taigidict.org/assets/leku-mp3.zip`
- Raw dictionary source: `https://app.taigidict.org/assets/kautian.ods`

Important distribution note:

- Because the upstream raw data is under `CC BY-ND 3.0 TW`, the app does not ship a preconverted SQLite database.
- Instead, the app downloads the raw `kautian.ods` file and builds the local SQLite database on the user's device.
- Runtime dictionary loading now prefers the locally built SQLite database in the app support directory. The old packaged dictionary asset is no longer used by the production app runtime.

## Tech Stack

- Flutter
- `dio` for resumable downloads
- `just_audio` for offline audio playback
- `flutter_open_chinese_convert` for runtime OpenCC conversion
- `adaptive_platform_ui` for cross-platform adaptive Material/Cupertino components
- `path` and `path_provider` for local file management
- `shared_preferences` for user settings, bookmarks, and search history
- `share_plus` for native sharing
- `spreadsheet_decoder` for parsing `kautian.ods`
- `sqflite` for the local SQLite dictionary database

## Project Structure

- `lib/main.dart`: app entry point
- `lib/app/`: app shell, navigation, and theme bootstrap
- `lib/app/initialization/`: first-run download and dictionary build gating flow
- `lib/app/shell/`: main three-tab app shell
- `lib/core/`: constants, localization, translation, and shared preferences
- `lib/features/dictionary/`: dictionary models, search, SQLite build/load logic, and UI
- `lib/features/audio/`: offline audio archive download, indexing, and playback
- `lib/features/bookmarks/`: bookmark persistence and screens
- `lib/features/settings/`: settings UI, offline resource controls, and localized reference articles
- `lib/features/settings/presentation/content/reference_articles.dart`: localized Tailo and Hanji reference article content
- `tool/build_dictionary_asset.py`: Python conversion script kept as a reference for the Dart-side ODS-to-SQLite mapping logic

## Offline Resource Flow

- The app does not ship a prebuilt SQLite dictionary database.
- It downloads the raw `kautian.ods` source and builds the local database on the device.
- Dictionary audio is managed separately as downloadable ZIP archives for word audio and sentence audio.
- Settings includes maintenance actions for re-downloading archives and rebuilding the local dictionary database.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## iOS Setup

The iOS project is configured with:

- deployment target `iOS 13.0`
- localized app metadata for `zh-Hant`, `zh-Hans`, and `en`
- adaptive iOS UI surfaces using Cupertino navigation plus `adaptive_platform_ui`

After dependency or Pod changes:

```bash
flutter pub get
cd ios
pod install
cd ..
```

## Development Notes

- `pubspec.yaml` currently pins `path_provider_foundation` with `dependency_overrides` to `2.6.0`.
- Keep that override unless you have verified a newer resolver result against the current iOS project and plugin set.
- This project uses a git dependency for `spreadsheet_decoder`, so dependency resolution is not fully reproducible from pub.dev alone.

## Build Release APK

```bash
flutter build apk --release
```

Generated artifact:

- `build/app/outputs/flutter-apk/app-release.apk`

## Acknowledgments

- Ministry of Education Taiwanese Hokkien Dictionary: `https://sutian.moe.edu.tw/`
- Tauhu-oo (豆腐烏) 20.05 font for Taiwanese Hanzi and specific CJK Extension glyph coverage: `https://github.com/tauhu-tw/tauhu-oo`
- jf open-huninn (jf open 粉圓) font used in the app icon artwork: `https://github.com/justfont/open-huninn-font`
- Adaptive Platform UI for adaptive Material/Cupertino UI components: `https://github.com/berkaycatak/adaptive_platform_ui`
- Open Chinese Convert for Flutter for runtime OpenCC conversion: `https://github.com/zonble/flutter_open_chinese_convert`

## License

- App code: MIT. See `LICENSE`.
- Dictionary data: `CC BY-ND 3.0 TW`. See `DATA_LICENSE.md`.
- Dictionary audio: `CC BY-ND 3.0 TW`. See `DATA_LICENSE.md`.
- Ministry copyright note: `https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/`
