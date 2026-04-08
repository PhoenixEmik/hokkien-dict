# 台語辭典

Offline Flutter dictionary app for Taiwanese Hokkien and Mandarin, built from
the Ministry of Education dataset and designed for local lookup on iOS and
Android.

## Data Source

- Canonical reference: `https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/`
- Source spreadsheet: `https://sutian.moe.edu.tw/media/senn/ods/kautian.ods`
- Audio source page: `https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/`
- Bundled dictionary asset: `assets/data/dictionary.json.gz`

## Current Features

- Offline dictionary lookup for Taiwanese headwords, romanization, and Mandarin definitions
- Tone-insensitive pinyin search
- Weighted result ranking with background-isolate search execution
- Search history stored locally with `shared_preferences`
- Bookmark tab for saved entries
- Dedicated word detail screen with audio playback
- Interactive linked definitions: bracketed references such as `【母】` can open another entry
- Offline audio archive download and playback for word and sentence clips
- Reading text size adjustment
- Theme selector with `System`, `Light`, `Dark`, and strict `AMOLED Black` modes
- Standard Material 3 settings/about flow

## Tech Stack

- Flutter
- `shared_preferences` for user preferences, search history, bookmarks, and theme persistence
- `just_audio` for local audio playback
- `path_provider` for offline archive storage

## Project Structure

The app is no longer a single large `main.dart`. It is split by responsibility:

- `lib/main.dart`: app entry point and exports used by tests
- `lib/app/`: app bootstrap, shell, and theme configuration
- `lib/core/`: shared app-wide state such as persisted preferences
- `lib/features/dictionary/`: dictionary models, search logic, screens, and widgets
- `lib/features/bookmarks/`: bookmark persistence and bookmarks screen
- `lib/features/settings/`: settings screen and settings widgets
- `lib/features/audio/`: offline audio archive storage, playback, and diagnostics
- `lib/offline_audio.dart`: compatibility export for audio types/services
- `tool/build_dictionary_asset.py`: converts the upstream ODS into the bundled gzip JSON asset
- `data/source/kautian.ods`: local copy of the ministry source spreadsheet

## Regenerate Dictionary Data

If the upstream ODS changes, rebuild the packaged dictionary asset:

```bash
python3 tool/build_dictionary_asset.py
```

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

## Build Release APK

```bash
flutter build apk --release
```

Generated artifact:

- `build/app/outputs/flutter-apk/app-release.apk`

## License

- App code: MIT. See `LICENSE`.
- Dictionary data: CC BY-NC-ND 2.5 TW. See `DATA_LICENSE.md`.
- Dictionary audio: sourced from the same ministry reference above and remains separately licensed.

## Delivery Notes

- Android and iOS app display names are set to `台語辭典`.
- The project still needs production application identifiers before store release.
- Release signing is not configured in this repository. Add your own Android keystore and Apple signing settings before publishing.
