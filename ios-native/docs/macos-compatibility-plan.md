# macOS Compatibility Plan

Assessed on 2026-05-27.

## Goal

Make the current Swift-native `台語辭典` project run on macOS without changing product identity, dictionary behavior, offline resource boundaries, or localization support.

This plan is for the native Swift code under `ios-native/`. It does not modify legacy Flutter code.

## Current State

### What is already ready

- `Package.swift` already declares:
  - `.iOS(.v17)`
  - `.macOS(.v14)`
- `swift test` passes on macOS as of 2026-05-27.
  - Result: `123` tests passed.
  - Target platform reported by SwiftPM: `arm64e-apple-macos14.0`
- Most business logic already lives in shared Swift package targets:
  - `TaigiDictCore`
  - `TaigiDictUI`
- Some UI files already contain native macOS branches, which means the codebase has already started preparing for direct macOS compilation rather than only iOS:
  - `Sources/TaigiDictUI/Initialization/InitializationScreen.swift`
  - `Sources/TaigiDictUI/Bookmarks/BookmarksScreen.swift`
  - `Sources/TaigiDictUI/Info/AboutScreen.swift`
  - `Sources/TaigiDictUI/Info/ThirdPartyLicenseCatalog.swift`

### What is not ready yet

- The Xcode app target is still iOS-only.
  - `TaigiDictNative.xcodeproj/project.pbxproj` currently sets:
    - `SDKROOT = iphoneos`
    - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`
    - `SUPPORTS_MACCATALYST = NO`
    - `TARGETED_DEVICE_FAMILY = "1,2"`
- There is no dedicated macOS app target, macOS Info.plist setup, or macOS app assets.
- UI verification currently covers Swift package tests, not a desktop app build or macOS UI flow.

## Recommendation

Recommend a native macOS SwiftUI app target, not Mac Catalyst as the primary path.

Why:

- The package layer already compiles and tests on native macOS.
- The UI code already has `os(macOS)` branches, which is a stronger fit for a direct macOS target than Catalyst.
- A native macOS target keeps desktop-specific behavior explicit instead of carrying iOS assumptions into desktop runtime.
- It matches the repository direction better: preserve product behavior, but use native platform patterns.

Mac Catalyst can remain a fallback option only if the goal changes to “ship the fastest possible Mac build with minimum desktop polish.”

## Main Gaps To Address

### 1. App target and bundle configuration

Current issue:

- `NativeApp/TaigiDictNativeApp.swift` is embedded only in an iOS application target.
- The Xcode project does not produce a macOS app product.

Required work:

- Add a macOS app target that links `TaigiDictCore` and `TaigiDictUI`.
- Add macOS bundle metadata while preserving the bundle identifier `org.taigidict.app` unless distribution constraints require a target-specific variant.
- Add localized macOS app metadata equivalent to the current `NativeApp/*.lproj/InfoPlist.strings`.
- Decide whether to share the existing asset catalog or introduce a small macOS-specific catalog overlay.

### 2. Root app bootstrapping and storage paths

Current issue:

- `NativeApp/TaigiDictNativeApp.swift` directly resolves `Application Support` paths inside the app target.
- This probably works on macOS, but the path policy is app-target-owned rather than shared and testable.

Required work:

- Extract app storage path construction into a small shared abstraction in `TaigiDictCore` or a shared app-support helper.
- Verify the same storage layout rules for:
  - dictionary source
  - installed dictionary database
  - offline audio archives
- Confirm macOS sandbox expectations if the app is later archived or distributed outside local debug builds.

### 3. Dictionary navigation behavior on desktop

Current issue:

- `Sources/TaigiDictUI/Dictionary/DictionarySearchScreen.swift` resolves layout from `horizontalSizeClass`.
- On macOS, size class assumptions are weaker and may fall back to the compact stack path, which is not the intended desktop experience.

Required work:

- Introduce an explicit macOS presentation rule.
- Prefer split navigation for macOS dictionary browsing by default.
- Ensure entry detail selection remains stable when:
  - search results update
  - history queries are replayed
  - linked-entry navigation pushes or replaces detail content

Recommended result:

- Keep the existing Dictionary / Bookmarks / Settings product areas.
- Use a desktop-appropriate split experience inside dictionary browsing first.
- Avoid a large IA rewrite in the first compatibility pass.

### 4. Bookmarks desktop interactions

Current issue:

- `Sources/TaigiDictUI/Bookmarks/BookmarksScreen.swift` already has a non-iOS branch.
- However, the macOS branch currently drops the iOS editing toolbar flow, so bulk selection and deletion behavior are not yet desktop-complete.

Required work:

- Add native macOS actions for:
  - delete selected bookmarks
  - select all / clear selection
  - open selected entry
- Support keyboard-first interaction where practical.
- Decide whether these actions live in:
  - toolbar buttons
  - context menus
  - command menus

### 5. Settings and maintenance flow on macOS

Current issue:

- `SettingsScreen` and `AdvancedSettingsScreen` are mostly portable, but they have not been validated as desktop workflows.
- Maintenance actions are operationally important because this app manages dictionary source restore, rebuild, and audio downloads.

Required work:

- Validate all settings flows in a macOS app build:
  - interface language
  - theme
  - reading text size
  - audio archive download / pause / resume / restart
  - rebuild / clear
- Confirm long-running maintenance actions remain understandable in a desktop window size and support multiple window resizes.

### 6. Audio playback and offline resource validation

Current issue:

- `Sources/TaigiDictCore/Data/Audio/AudioPlaybackService.swift` uses `AVAudioPlayer`.
- The service already avoids `AVAudioSession` on macOS, which is good, but actual desktop playback behavior still needs app-level verification.

Required work:

- Verify word audio and example audio playback on macOS.
- Verify archive downloads and ZIP indexing from a macOS app run.
- Confirm failure states remain user-readable when files are missing, corrupt, or partially downloaded.

### 7. Test and CI coverage

Current issue:

- Current confidence is strong at the package level, but weak at the app-target level for macOS.

Required work:

- Add at least one command-line macOS app build verification path.
- Add a CI job for:
  - `swift test`
  - macOS app build
- Add targeted tests for new platform presentation decisions if logic is extracted into testable helpers.

## Proposed Phases

### Phase 1: Bootstrap a macOS app target

Deliverables:

- New macOS app target in `TaigiDictNative.xcodeproj`
- macOS app entry point reusing current root view composition
- localized app metadata for macOS
- documented build command in `README.md`

Acceptance:

- The app launches on macOS.
- Initialization can complete using bundled dictionary resources.
- Search, detail, bookmarks, and settings all open without crashing.

### Phase 2: Make the primary desktop flows usable

Deliverables:

- explicit macOS dictionary presentation
- stable split navigation behavior
- desktop-capable bookmark actions
- toolbar / menu adjustments where needed

Acceptance:

- Dictionary browsing feels like a desktop app, not a stretched phone flow.
- A user can search, inspect detail, bookmark, unbookmark, and reopen bookmarks efficiently with mouse and keyboard.

### Phase 3: Validate maintenance and offline resources

Deliverables:

- verified dictionary restore / rebuild flow on macOS
- verified audio download lifecycle on macOS
- clear failure messaging for damaged or missing local resources

Acceptance:

- The app can recover from missing local resources without manual file intervention.
- Audio archive state remains correct across relaunch.

### Phase 4: Formalize verification and release readiness

Deliverables:

- macOS build command added to docs
- CI build coverage for macOS
- regression checklist for localization, storage, audio, and navigation

Acceptance:

- A PR can prove macOS compatibility without requiring manual Xcode-only inspection.

## Suggested Implementation Order

1. Add the macOS app target and make it compile.
2. Extract shared app storage path logic out of the current iOS app entry.
3. Fix dictionary presentation so macOS defaults to split navigation.
4. Complete bookmark desktop actions.
5. Verify settings, maintenance, and offline audio flows in a real macOS app run.
6. Add macOS build verification to docs and CI.

## Risks And Decisions To Lock Early

### Decision: native macOS target vs Mac Catalyst

Recommended:

- native macOS target

Reason:

- Better alignment with current package platform support and existing `os(macOS)` code.

### Decision: first-pass information architecture

Recommended:

- Keep the existing top-level product areas:
  - Dictionary
  - Bookmarks
  - Settings
- Do not redesign the whole app shell in the first pass.

Reason:

- The goal is compatibility first, not feature expansion or product re-architecture.

### Decision: storage layout

Recommended:

- Preserve separate storage boundaries for:
  - source package
  - installed dictionary database
  - offline audio archives
  - user data such as bookmarks and preferences

Reason:

- This is core product behavior and tied to current maintenance flows.

## Definition Of Done

macOS compatibility should be considered complete only when all of the following are true:

- A macOS app target exists and builds from the project.
- The app launches and reaches the main UI on macOS.
- Dictionary search, entry detail, bookmarks, and settings are all usable on macOS.
- Dictionary rebuild / clear and audio archive flows are verified on macOS.
- Localization still works for `zh-Hant`, `zh-Hans`, and `en`.
- The verification path is documented and can run in CI.
