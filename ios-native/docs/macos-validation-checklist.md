# macOS Validation Checklist

Assessed on 2026-05-27.

## Automated Verification

Run the standard macOS verification entrypoint from `ios-native/`:

```bash
./Scripts/verify_macos.sh
```

Current coverage:

- `swift test`
- `xcodebuild -workspace TaigiDictNative.xcworkspace -scheme TaigiDictNativeMac -destination 'platform=macOS' build`

## Manual Validation

Open `TaigiDictNative.xcworkspace`, choose `TaigiDictNativeMac`, and validate the flows below on macOS.

### 1. First launch and initialization

- App launches to the initialization screen without crashing.
- Bundled dictionary resources are found.
- Initialization finishes and reaches the main UI.

### 2. Dictionary

- Search field accepts Hanji, Tailo, and Mandarin queries.
- Search results update and selecting a result updates the detail pane.
- Detail content remains readable when the window is resized.
- Linked references open the expected entry.
- Bookmark and share actions appear and work.

### 3. Bookmarks

- Bookmarks list appears in the left pane.
- Selecting one bookmark shows its detail in the right pane.
- Multi-selection works in the bookmarks list.
- `Select All` / `Deselect All` behave correctly.
- `Delete Selected` removes only the selected rows.
- Right-click context menu can delete or share a bookmark.

### 4. Settings and maintenance

- Interface language switching updates visible UI.
- Theme preference applies correctly.
- Reading text scale updates visible text sizing.
- Dictionary source can be restored from the app bundle.
- Dictionary source can be refreshed from the network.
- Advanced settings opens.
- `Rebuild` completes and the dictionary remains usable afterward.
- `Clear` removes installed data and the app can recover cleanly.

### 5. Offline resources and audio

- Word audio and example audio can play after resources are present.
- Audio download can start, pause, resume, and restart.
- Download state survives refresh and relaunch.
- Broken or missing archive states show readable failure messaging.

## CI Status

The repository now includes a root GitHub Actions workflow for this verification path:

- [ios_native_macos.yml](/Users/emik/repository/taigi-dict/.github/workflows/ios_native_macos.yml)

That workflow runs:

- `cd ios-native && ./Scripts/verify_macos.sh`
