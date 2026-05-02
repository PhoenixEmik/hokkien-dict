# Swift Native Localization String Resource Strategy

## Goal
Use one localization key set for all Swift-native screens and make migration to bundle-based resources predictable.

## Current baseline
- UI strings are centralized in `AppLocalizer` with `AppLocalizedStringKey`.
- Screens resolve locale via `AppLocalizer.appLocale(from: locale)`.
- View models should expose semantic keys where possible (for example, status keys) rather than hardcoded user-facing strings.

## Key design rules
- Add every new user-facing string as an `AppLocalizedStringKey` first.
- Keep keys semantic, not language-dependent.
- Prefer one key per message. Reuse keys only when wording is intentionally identical.
- Keep string interpolation outside key definitions unless the sentence template itself must be localized.

## Screen integration pattern
1. Read `@Environment(\.locale)` in the view.
2. Convert to `AppLocale` once in the view.
3. Resolve strings via `AppLocalizer.text(key, locale: appLocale)`.
4. Pass localized strings to child views if they do not own locale context.

## ViewModel integration pattern
- Expose `AppLocalizedStringKey?` for success/info statuses.
- Keep backend/library errors as raw strings when they are runtime-dependent.
- Convert status keys to text in the view layer.

## Resource file migration plan (.xcstrings)
1. Keep `AppLocalizedStringKey` as the source of truth for call sites.
2. Introduce `Localizable.xcstrings` in the Swift package resources.
3. Add mapping in `AppLocalizer` from `AppLocalizedStringKey` to string catalog IDs.
4. Resolve through `String(localized:bundle:)` with `Bundle.module`.
5. Keep current in-code fallback tables during transition.
6. Remove fallback tables only after CI validates complete key coverage.

## Auto-export workflow
1. Update `AppLocalizedStringKey` and the three locale tables in `AppLocalizer.swift`.
2. Run `./Scripts/export_xcstrings_skeleton.swift` from `ios-native`.
3. Commit both source and generated catalog changes together.

## Consistency check workflow
1. Run `./Scripts/export_xcstrings_skeleton.swift --check` from `ios-native`.
2. Treat non-zero exit as a release/CI blocker.
3. If check fails, re-run export and review any missing or extra keys.

## Validation checklist
- No hardcoded user-facing strings in `TaigiDictUI` screens for dictionary, bookmarks, initialization, and settings flows.
- New keys have Traditional Chinese, Simplified Chinese, and English entries.
- Tests cover view model key outputs when applicable.
- Locale switching reflects immediately in active views.
