# AGENTS.md — Android Native Rewrite Instructions

You are working on rewriting an existing Flutter dictionary app into a native Android app.

The repository root is `Hokkien/`.

Existing app/reference sources:
- Flutter app: inspect the existing Flutter source in this repository.
- iOS native app: inspect `swift-native/` and use it as the newer product/reference implementation when behavior differs from Flutter.
- The Android native app should live under `android-native/`.

## Primary goal

Rebuild the app as a high-quality native Android app using:

- Kotlin
- Jetpack Compose
- Material 3
- AndroidX ViewModel
- Kotlin coroutines and Flow/StateFlow
- A clean separation between UI, domain logic, and data access

Do not merely translate Dart code line-by-line into Kotlin. First infer the product behavior, data model, navigation, search behavior, localization needs, and UX flows. Then implement them in idiomatic Android.

## Product type

This is a Hokkien/Taiwanese dictionary app. Prioritize:

- Fast local search
- Clear dictionary entry display
- Offline-first behavior
- Correct handling of Chinese characters, romanization, pronunciation fields, definitions, examples, and related metadata
- Good text rendering
- Good keyboard/search UX
- Traditional Chinese and English localization readiness
- Dark mode
- Accessibility and dynamic font scaling

## Architecture rules

Use this general structure unless the existing project strongly suggests otherwise:

```text
android-native/
  app/
    src/main/
      java|kotlin/<package>/
        MainActivity.kt
        ui/
          screens/
          components/
          theme/
          navigation/
        feature/
          search/
          entry/
          settings/
          favorites/
        data/
          local/
          repository/
          model/
        domain/
          model/
          usecase/
        i18n/
      res/
        values/
        values-zh-rTW/
        values-en/
        drawable/
        mipmap/