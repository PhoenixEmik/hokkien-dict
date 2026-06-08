# Taigi Dict Android Native

This directory contains the native Kotlin / Jetpack Compose version of Taigi
Dict.

The app is built as a single Android application module with a generated
dictionary package and an on-device database pipeline:

- `app`: production Android app, Compose UI, navigation, data layer, and tests
- `Generated/Dictionary`: bundled dictionary manifest and JSONL entry package
- `gradle/` and Gradle wrapper files: project build and dependency setup

## Current App Scope

The Android native app currently includes:

- dictionary search with adaptive Compose layouts for phone and larger screens
- entry detail pages with linked references, bookmarks, share, and audio actions
- bookmarks with native Android interaction patterns
- settings for language, theme, reading text size, offline audio, and advanced maintenance
- initialization flow that can restore bundled dictionary source, download source data, and rebuild the local database
- bundled reference articles, about, privacy, license, and third-party license screens
- simplified/traditional conversion through `android-opencc`
- default SQLite-backed repository wiring, with a Room-backed debug path also present in the project

## Requirements

- Android Studio with Android SDK 36 installed, or a working local Gradle setup
- JDK 17
- Android 7.0 or newer device / emulator target

## Build And Run

Open the `android-native/` directory in Android Studio and run the `app`
module on an emulator or device.

Command-line debug build:

```bash
./gradlew app:assembleDebug
```

Optional Room-backed debug variant:

```bash
./gradlew assembleRoomDebug
```

Release APK build:

```bash
./gradlew :app:assembleRelease
```

If `key.properties` is present, the release build uses that signing
configuration. Otherwise it falls back to the debug signing config.

## Project Layout

```text
android-native/
  app/
    src/
      main/
        assets/
        kotlin/org/taigidict/app/
        res/
      test/
      androidTest/
      roomDebugUnitTest/
  Generated/
    Dictionary/
  gradle/
  gradlew
  gradlew.bat
  build.gradle.kts
  settings.gradle.kts
```

Notable source areas:

- `app/src/main/kotlin/org/taigidict/app/app`
  application setup, dependency container, and app state
- `app/src/main/kotlin/org/taigidict/app/navigation`
  top-level tab destinations and adaptive navigation shell
- `app/src/main/kotlin/org/taigidict/app/feature/dictionary`
  search UI, detail UI, linked-word handling, and share formatting
- `app/src/main/kotlin/org/taigidict/app/feature/bookmarks`
  bookmarks UI and state handling
- `app/src/main/kotlin/org/taigidict/app/feature/settings`
  settings UI, offline resource controls, and maintenance actions
- `app/src/main/kotlin/org/taigidict/app/feature/initialization`
  first-run readiness checks, bundled restore, download, and rebuild flow
- `app/src/main/kotlin/org/taigidict/app/feature/info`
  about, licenses, privacy, and reference article screens
- `app/src/main/kotlin/org/taigidict/app/data`
  audio, database, importer, repository, search history, and source resource management
- `app/src/main/kotlin/org/taigidict/app/domain`
  domain models and search service

## Dependencies

Current primary dependencies:

- Jetpack Compose Material 3
- AndroidX Lifecycle ViewModel and runtime compose integrations
- Preferences DataStore
- Room
- Kotlin serialization JSON
- `android-opencc` `1.4.1`
- Robolectric for local JVM-side Android tests

## Data Boundaries

- Native Android code lives under `android-native/`.
- The app bundles generated dictionary resources under `Generated/Dictionary/`.
- On first run, the app can build the local SQLite dictionary database from bundled or downloaded source resources.
- The app can also restore bundled source data or download updated source data into app-local storage for rebuilds.
- The default repository backend is SQLite, selected through `BuildConfig`.
- A Room-backed repository implementation is also present for parity and verification work.

The Android app entry points are:

- `app/src/main/kotlin/org/taigidict/app/MainActivity.kt`
- `app/src/main/kotlin/org/taigidict/app/app/TaigiDictApplication.kt`

## Testing

Local unit tests:

```bash
./gradlew testDebugUnitTest
```

Instrumented test build verification:

```bash
./gradlew app:assembleDebugAndroidTest
```

Room-backed verification task:

```bash
./gradlew verifyRoomDebug
```

## Notes

- The project currently targets `compileSdk = 36`, `targetSdk = 36`, and `minSdk = 24`.
- The generated dictionary package is exposed to the app through Gradle asset source sets.
- Chinese conversion should go through the app conversion abstractions in `data/conversion`, not direct package calls from UI code.
- The Android app is intended to preserve product behavior while using idiomatic Compose and Android architecture rather than copying another platform's structure directly.
