# Hokkien Repository Instructions

This repository contains the Hokkien dictionary project, a Taiwanese Hokkien / Mandarin dictionary app named `台語辭典`.

The repository contains multiple implementations and support files for the same product. Treat this as a multi-target app repository, not as a single Flutter-only project.

## Repository layout

Current important paths:

- `lib/`: legacy Flutter application source.
- `ios/`: legacy Flutter-generated iOS project.
- `android/`: legacy Flutter-generated Android project.
- `test/`: legacy Flutter tests.
- `tool/`: legacy/support tooling, including dictionary data processing references.
- `assets/`: shared or legacy Flutter assets.
- `docs/`: project documentation.
- `ci_scripts/`: CI/support scripts.
- `.github/workflows/`: GitHub Actions workflows.
- `ios-native/`: native iOS rewrite written in Swift.
- `android-native/`: native Android rewrite written in Kotlin.
- `DATA_LICENSE.md`: licensing notes for dictionary data and audio.
- `PRIVACY_POLICY.md`: bilingual privacy policy.
- `README.md` and `README.zh-Hant.md`: product and project overview.

## General rule

Do not modify legacy Flutter code unless explicitly asked.

Legacy Flutter code includes, but is not limited to:

- `lib/`
- `ios/`
- `android/`
- `test/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- Flutter-specific files under `tool/`

Do not modify native iOS code unless the task is specifically about the native iOS app.

Do not modify native Android code unless the task is specifically about the native Android app.

When working inside a native app directory, also follow the local instructions in that directory.

For native iOS work, follow:

- `ios-native/AGENTS.md`

For native Android work, follow:

- `android-native/AGENTS.md`

If a local `AGENTS.md` conflicts with this root file, follow the more specific local instruction for files under that directory.

## Product identity

The app is `台語辭典`.

Preserve these product identifiers unless explicitly asked to change them:

- App display name: `台語辭典`
- Android application ID: `org.taigidict.app`
- iOS bundle identifier: `org.taigidict.app`
- Official project domain: `https://taigidict.org`
- Production asset host: `https://app.taigidict.org/assets/`

Do not casually rename app identifiers, bundle identifiers, package names, domains, asset hosts, or public-facing product names.

## Product behavior

The app is organized around these primary areas:

1. Dictionary
   - Search Taiwanese headwords.
   - Search Tailo romanization.
   - Search Mandarin definitions.
   - Reuse recent searches.
   - Open a dedicated detail page for each entry.

2. Bookmarks
   - Save dictionary entries.
   - Reopen saved entries.
   - Keep the localized entry detail behavior consistent with dictionary search.

3. Settings
   - Manage offline resources.
   - Manage appearance.
   - Manage language.
   - Manage reading text size.
   - Show reference material.
   - Show about/license/privacy information.

The first-run and offline-data experience is part of the product, not an implementation detail.

The app can restore a bundled `kautian.ods` source file, build a local SQLite dictionary on-device, and then use that database for subsequent offline lookup.

## Dictionary data and licensing

Be very careful with dictionary data.

The app uses Ministry of Education Taiwanese Hokkien dictionary data.

Important rule:

Do not ship a preconverted SQLite dictionary database unless explicitly asked and unless the licensing implications have been reviewed.

The upstream raw data is under `CC BY-ND 3.0 TW`. The current product design avoids shipping a preconverted SQLite database. Instead, the app ships or restores the raw `kautian.ods` source and builds the local SQLite database on the user's device.

Runtime dictionary loading should prefer the locally built SQLite database in the app support directory.

If changing dictionary data behavior, document the licensing and distribution impact.

## Offline resource flow

The production offline resource endpoints include:

- Dictionary audio archive: `https://app.taigidict.org/assets/sutiau-mp3.zip`
- Example audio archive: `https://app.taigidict.org/assets/leku-mp3.zip`
- Raw dictionary source: `https://app.taigidict.org/assets/kautian.ods`

Settings may include maintenance actions for:

- Re-downloading `kautian.ods`
- Rebuilding the local dictionary database
- Downloading or repairing dictionary audio archives
- Downloading or repairing example audio archives

Dictionary audio and example audio are managed separately from the dictionary SQLite database.

Do not merge these resource flows unless explicitly requested.

## Source-of-truth guidance

The Flutter app is the legacy/reference implementation.

The native iOS app under `ios-native/` may represent newer intended product behavior.

The native Android app under `android-native/` may be a work-in-progress rewrite.

When behavior differs between Flutter and native iOS, do not assume which one is correct. Inspect both implementations and document the difference before making changes.

For future Android native work, use both the Flutter app and `ios-native/` as behavioral references. Preserve product behavior, but implement Android UI and architecture idiomatically.

Do not translate Flutter/Dart code line-by-line into Swift or Kotlin.

First understand:

- Product behavior
- Dictionary data format
- SQLite schema/build flow
- Search behavior and ranking
- Navigation flow
- Bookmark behavior
- Search history behavior
- Settings behavior
- Offline resource behavior
- Audio download/playback behavior
- Localization behavior
- Accessibility behavior

Then implement using the conventions of the target platform.

## Native iOS guidance

Native iOS work belongs under:

- `ios-native/`

Use the local iOS instructions in:

- `ios-native/AGENTS.md`

In general:

- Prefer native SwiftUI and UIKit patterns.
- Do not recreate Flutter widgets manually.
- Prefer system navigation, system search, system lists, forms, sheets, alerts, menus, buttons, and toolbars.
- Use Dynamic Type, Dark Mode, VoiceOver, system colors, system fonts, and SF Symbols.
- Avoid fake Liquid Glass, excessive custom blur, custom tab bars, custom navigation bars, and decorative UI that fights the system.
- The dictionary content is the app's personality. Prioritize readability.

## Native Android guidance

Native Android work belongs under:

- `android-native/`

Use the local Android instructions in:

- `android-native/AGENTS.md`

This is a normal native Android app written in Kotlin.

Do not interpret `android-native/` as:

- the legacy Flutter `android/` folder
- a Kotlin Multiplatform project
- a Kotlin/Native target
- a Dart-to-Kotlin translation output

Unless explicitly requested, native Android should use:

- Kotlin
- Jetpack Compose
- Material 3
- AndroidX ViewModel
- Kotlin coroutines
- Flow / StateFlow
- Repository/data-layer separation
- Android string resources
- Android-native navigation and back behavior

Preserve product behavior, but make the Android UI feel native to Android.

## Legacy Flutter guidance

The legacy Flutter app remains an important reference implementation.

Important Flutter locations:

- `lib/main.dart`: app entry point.
- `lib/app/`: app shell, navigation, and theme bootstrap.
- `lib/app/initialization/`: first-run bundled-source restore and dictionary build gating flow.
- `lib/app/shell/`: main three-tab app shell.
- `lib/core/`: constants, localization, translation, and shared preferences.
- `lib/features/dictionary/`: dictionary models, search, SQLite build/load logic, and UI.
- `lib/features/audio/`: offline audio archive download, indexing, and playback.
- `lib/features/bookmarks/`: bookmark persistence and screens.
- `lib/features/settings/`: settings UI, offline resource controls, and localized reference articles.
- `lib/features/settings/presentation/content/reference_articles.dart`: localized Tailo and Hanji reference article content.
- `tool/build_dictionary_asset.py`: Python conversion script kept as a reference for the Dart-side ODS-to-SQLite mapping logic.

Do not change Flutter code unless explicitly asked.

If you inspect Flutter code to understand behavior, say that you inspected it, but keep your implementation changes in the requested native target.

## Search behavior

Search is core product behavior.

Before changing search behavior, inspect the existing implementation.

Search should account for:

- Taiwanese headwords
- Tailo romanization
- Mandarin definitions
- weighted ranking
- recent search history
- exact matches
- prefix matches
- partial matches
- romanization normalization
- Chinese text handling
- empty query behavior
- no-result behavior
- localized result display

Do not silently change ranking rules.

If search behavior is ambiguous, document the assumption in the relevant native app docs before implementing.

## Bookmarks and user data

Bookmarks, search history, language, theme, reading text size, and offline resource state are user data.

Do not mix user data with bundled dictionary data.

For native rewrites:

- Keep bundled/raw dictionary source data separate from user-generated data.
- Keep locally built dictionary databases separate from user settings and bookmarks.
- Preserve user data across app restarts.
- Avoid UI-thread disk I/O.
- Document persistence choices.

## Localization

The app supports localized UI.

Avoid hardcoded user-facing strings in native app code.

For iOS:

- Use the localization system under `ios-native/`.
- Preserve localized app metadata where present.
- Consider `zh-Hant`, `zh-Hans`, and `en` where relevant.

For Android:

- Use Android string resources under `android-native/`.
- Prepare or maintain resources such as:
  - `res/values/strings.xml`
  - `res/values-zh-rTW/strings.xml`
  - `res/values-en/strings.xml`

When adding or changing user-visible text, consider Traditional Chinese and English localization.

Do not treat localization as a final cleanup task. Build it into the implementation from the beginning.

## Reference articles and licenses

The app includes reference material such as Tailo and Hanji guides, plus about/license/privacy information.

Do not remove or rewrite reference material casually.

If migrating reference articles into a native app:

- Preserve meaning.
- Preserve localization.
- Preserve attribution and license information.
- Prefer native text layouts and native navigation.
- Keep long-form reference content readable.

## Generated files and shared assets

Be careful with generated dictionary data, generated code, and shared assets.

Before modifying generated files, identify the source script or generation process.

Prefer changing the generator rather than manually editing generated output.

Do not move, rename, or delete shared data files unless the task explicitly requires it.

If a change affects both native apps or the legacy Flutter app, document the expected cross-platform impact.

## Build and verification

Use the relevant verification commands for the part of the repo being changed.

For legacy Flutter:

- `flutter analyze`
- `flutter test`

For native iOS:

- Use the build/test command documented under `ios-native/`.
- If no command is documented, inspect the Xcode project/workspace and propose a safe command before running it.

For native Android:

- Use the Gradle wrapper or Gradle command documented under `android-native/`.
- If no command is documented, inspect the project structure and propose a safe command before running it.

Do not claim a build or test passed unless you actually ran it.

If you cannot run a build or test, say why.

## Work process

For substantial changes:

1. Inspect the relevant existing implementation first.
2. Summarize what behavior currently exists.
3. Propose a short implementation plan.
4. Make a focused change.
5. Build or run tests where practical.
6. Report what changed, what was verified, and what remains uncertain.

Prefer small, reviewable changes over large rewrites.

Do not perform speculative refactors unless explicitly asked.

Do not combine unrelated changes.

## Git and file movement rules

When renaming or moving major directories, use `git mv` where possible.

Keep pure renames separate from content changes so Git can preserve file history clearly.

Do not mix large folder renames with formatting, restructuring, dependency updates, or feature work in the same change.

Before moving a directory, check whether the destination already exists.

If the destination exists, do not accidentally create nested paths such as:

- `ios-native/ios-native/`

When uncertain, stop and explain the intended move before doing it.

## AI agent safety rules

Do not delete source files, generated data, project files, build scripts, release assets, or documentation unless explicitly asked.

Do not overwrite existing project structure without first explaining the impact.

Do not create a Kotlin Multiplatform project unless explicitly requested.

Do not create a Kotlin/Native project unless explicitly requested.

Do not create a new app identity, package name, bundle identifier, or asset host unless explicitly requested.

Do not invent new product features while migrating.

Do not add flashy UI effects, custom glassmorphism, decorative gradients, or custom system-control replacements unless explicitly requested.

When uncertain, document the assumption in a file under the relevant `docs/` directory instead of silently guessing.

## Default migration mindset

For every migration task, use this mindset:

1. Understand the existing product behavior.
2. Identify the closest native platform pattern.
3. Preserve dictionary-specific logic.
4. Use boring native system UI first.
5. Add custom UI only if it improves dictionary readability or usability.
6. Keep licensing, offline data, audio resources, localization, and accessibility intact.

The goal is not to preserve Flutter's implementation shape.

The goal is to preserve the product while making each native app feel truly native.