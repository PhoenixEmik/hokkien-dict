# Flutter Material 3 Migration Plan

## Goal

將 Flutter 端對 `adaptive_platform_ui` 的依賴完整移除，改用 Flutter 原生 Material 3 widget 與必要的少量平台判斷實作等效行為。

本文件聚焦於 Flutter UI 遷移範圍，不包含已經獨立重構的 `ios-native/` iOS 原生程式碼。

## Current Dependency State

- `pubspec.yaml` 目前仍包含 `adaptive_platform_ui: 0.1.105`
- Flutter `lib/` 內共有 22 個 Dart 檔案直接使用 `adaptive_platform_ui` 或 `PlatformInfo.isIOS`
- 主要依賴集中在 app shell、settings、dictionary、dialog / notification helper

## Scan Summary

本次掃描對象：`lib/**`、`pubspec.yaml`

受影響檔案：

1. `lib/app/app.dart`
2. `lib/app/shell/main_shell.dart`
3. `lib/core/utils/dialog_utils.dart`
4. `lib/features/bookmarks/presentation/screens/bookmarks_screen.dart`
5. `lib/features/dictionary/presentation/screens/dictionary_screen.dart`
6. `lib/features/dictionary/presentation/screens/word_detail_screen.dart`
7. `lib/features/dictionary/presentation/widgets/audio_button.dart`
8. `lib/features/dictionary/presentation/widgets/entry_list_item.dart`
9. `lib/features/dictionary/presentation/widgets/search_panel.dart`
10. `lib/features/dictionary/presentation/widgets/word_detail_sections.dart`
11. `lib/features/settings/presentation/screens/about_app_screen.dart`
12. `lib/features/settings/presentation/screens/advanced_settings_screen.dart`
13. `lib/features/settings/presentation/screens/license_overview_screen.dart`
14. `lib/features/settings/presentation/screens/license_summary_screen.dart`
15. `lib/features/settings/presentation/screens/reference_article_screen.dart`
16. `lib/features/settings/presentation/screens/settings_screen.dart`
17. `lib/features/settings/presentation/widgets/audio_resource_tile.dart`
18. `lib/features/settings/presentation/widgets/dictionary_source_resource_tile.dart`
19. `lib/features/settings/presentation/widgets/notification.dart`
20. `lib/features/settings/presentation/widgets/settings_locale_tile.dart`
21. `lib/features/settings/presentation/widgets/settings_text_scale_tile.dart`
22. `lib/features/settings/presentation/widgets/settings_theme_mode_tile.dart`
23. `pubspec.yaml`

元件 / API 使用熱點：

- `PlatformInfo.isIOS`: 48
- `AdaptiveListTile`: 31
- `AdaptiveButton`: 15
- `AdaptiveButtonStyle`: 12
- `AdaptiveButtonSize`: 12
- `AdaptiveFormSection`: 12
- `AdaptiveScaffold`: 11
- `AdaptiveAppBar`: 10
- `AdaptiveAlertDialog`: 4
- `AdaptiveNavigationDestination`: 3
- `AdaptiveAppBarAction`: 2
- `AdaptivePopupMenuButton`: 2
- `AdaptivePopupMenuItem`: 2
- `AdaptiveApp`: 1
- `AdaptiveTextField`: 1
- `AdaptiveSlider`: 1
- `AdaptiveSnackBar`: 1
- `AdaptiveBottomNavigationBar`: 1

依檔案複雜度排序的主要熱點：

1. `lib/features/settings/presentation/screens/about_app_screen.dart`
2. `lib/features/dictionary/presentation/widgets/search_panel.dart`
3. `lib/features/dictionary/presentation/screens/dictionary_screen.dart`
4. `lib/features/settings/presentation/screens/settings_screen.dart`
5. `lib/features/dictionary/presentation/widgets/audio_button.dart`
6. `lib/features/settings/presentation/screens/license_summary_screen.dart`
7. `lib/app/shell/main_shell.dart`
8. `lib/features/settings/presentation/screens/license_overview_screen.dart`
9. `lib/features/settings/presentation/screens/advanced_settings_screen.dart`

## Replacement Map

| Current API | Material 3 Replacement | Notes |
| --- | --- | --- |
| `AdaptiveApp` | `MaterialApp` | 直接使用 Material 3；若仍需 iOS 風格色彩，交由 `ThemeData` / `ColorScheme` 處理 |
| `AdaptiveScaffold` | `Scaffold` | 多數為 1:1 替換 |
| `AdaptiveAppBar` | `AppBar` | 需要手動補 `leading`, `actions`, `centerTitle` 等設定 |
| `AdaptiveAppBarAction` | `IconButton` | 放入 `AppBar.actions` |
| `AdaptiveBottomNavigationBar` | `NavigationBar` | Material 3 預設建議用 `NavigationBar`，非 `BottomNavigationBar` |
| `AdaptiveNavigationDestination` | `NavigationDestination` | 對應 `NavigationBar.destinations` |
| `AdaptiveListTile` | `ListTile` | 若有 iOS grouped 風格，交由 `Card` / `Container` / `ListTileTheme` 建構 |
| `AdaptiveFormSection.insetGrouped` | `Card` + `Column` + `ListTile` | 需要統一 section wrapper，避免每頁重複手寫 |
| `AdaptiveButton.child` | `TextButton` / `FilledButton` / `OutlinedButton` | 依原本 style intent 決定 |
| `AdaptiveButton.icon` | `TextButton.icon` / `FilledButton.icon` / `OutlinedButton.icon` | 與上列相同 |
| `AdaptiveButton.sfSymbol` | Material button + `Icon` | 將 SF Symbol 名稱改為 Material icon 對應 |
| `AdaptiveTextField` | `TextField` | 需要自己提供 `InputDecoration` 與 trailing clear button |
| `AdaptivePopupMenuButton` | `PopupMenuButton` / `MenuAnchor` | 以現況來說 `PopupMenuButton` 足夠 |
| `AdaptivePopupMenuItem` | `PopupMenuItem` | 幾乎 1:1 |
| `AdaptiveAlertDialog` | `AlertDialog` | 若未來還要 iOS 原生外觀，再另建 `CupertinoAlertDialog` helper |
| `AdaptiveSlider` | `Slider` | 1:1 替換 |
| `AdaptiveSnackBar` | `ScaffoldMessenger.showSnackBar` | 用 app-level helper 保持原有呼叫點簡潔 |
| `PlatformInfo.isIOS` | 優先移除；必要時改 `Theme.of(context).platform` | 本次目標是 Material 3，應盡量減少平台分叉 |

## Migration Principles

1. 先替換「框架型元件」，再替換頁面內局部 widget。
2. 優先建立共用 Material 3 wrapper，避免每個畫面各自重寫 grouped section、dialog、notification 樣式。
3. `PlatformInfo.isIOS` 只保留在確實需要平台圖示或安全區差異的地方。
4. iOS 不再追求 `adaptive_platform_ui` 的 Cupertino 模擬行為，改以 Material 3 一致體驗為主。
5. 先保留既有功能與資訊架構，避免遷移時同時做大規模視覺重設計。

## Suggested Shared Replacements To Create First

建議先建立以下共用元件 / helper，之後再逐頁替換：

1. `AppScaffold`
   - 封裝 `Scaffold`
   - 統一 top padding、safe area、scroll behavior

2. `AppSectionCard`
   - 取代 `AdaptiveFormSection.insetGrouped`
   - 統一 section header、card margin、tile divider、rounded corner

3. `AppDialog`
   - 封裝 `AlertDialog`
   - 取代目前的 `AdaptiveAlertDialog` helper

4. `AppNotification`
   - 封裝 `ScaffoldMessenger`
   - 取代 `AdaptiveSnackBar`

5. `AppMenuButton<T>`
   - 封裝 `PopupMenuButton<T>`
   - 取代 locale / theme 的 popup 選單重複邏輯

6. `AppActionButton`
   - 封裝小尺寸 icon / text action button
   - 取代 `AdaptiveButton.*` 的 `plain`, `gray`, `tinted` 分支

## File-By-File Inventory

### 1. `lib/app/app.dart`

目前用途：

- `AdaptiveApp`
- Cupertino theme 仍透過 adaptive app 注入

重構方向：

- 改為 `MaterialApp`
- 保留現有 locale / themeMode / delegates 設定
- `materialLightTheme` / `materialDarkTheme` 直接改為 `theme` / `darkTheme`
- 移除 `cupertinoLightTheme` / `cupertinoDarkTheme` 依賴

### 2. `lib/app/shell/main_shell.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveBottomNavigationBar`
- `AdaptiveNavigationDestination`
- 多個 `PlatformInfo.isIOS` icon 分支

重構方向：

- 用 `Scaffold` + `NavigationBar`
- 用 `NavigationDestination` 取代 adaptive destination
- 重新決定 icon 是否全面使用 Material icon，或保留少量平台圖示判斷
- 這是整體遷移的入口點之一，優先度高

### 3. `lib/core/utils/dialog_utils.dart`

目前用途：

- `AdaptiveAlertDialog.show`
- `AlertAction`
- `AlertActionStyle`
- adaptive icon string / iconData 混用

重構方向：

- 用 `showDialog` + `AlertDialog`
- 自行組出 actions 與可選 icon 區塊
- 若 icon 目前依賴 iOS SF Symbol 字串，需在 helper 內統一映射到 Material icon 或直接改呼叫端參數型別
- 這個 helper 會影響 settings 內多個 dialog，應優先完成

### 4. `lib/features/bookmarks/presentation/screens/bookmarks_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `PlatformInfo.isIOS` safe area / bottom inset 分支

重構方向：

- 用 `Scaffold` + `AppBar`
- 審視 `topBodyInset` / `bottomInset` 是否仍需要平台分叉；多數可改為單純 `SafeArea`

### 5. `lib/features/dictionary/presentation/screens/dictionary_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveButton.sfSymbol`
- `AdaptiveButton.icon`
- `AdaptiveButtonStyle.gray/plain`
- `AdaptiveButtonSize.small`
- 多個 `PlatformInfo.isIOS` 分支

重構方向：

- 頁面框架改為 `Scaffold` + `AppBar`
- 小型操作按鈕統一改成 `IconButton`, `TextButton.icon`, `FilledButton.tonalIcon` 或共用 `AppActionButton`
- 平台分叉優先改為單一 Material 按鈕樣式

### 6. `lib/features/dictionary/presentation/screens/word_detail_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveAppBarAction`
- `PlatformInfo.isIOS`

重構方向：

- `Scaffold` + `AppBar`
- `AdaptiveAppBarAction` 改為 `IconButton`
- 處理 share / bookmark actions 的 icon 與 tooltip

### 7. `lib/features/dictionary/presentation/widgets/audio_button.dart`

目前用途：

- `AdaptiveButton.child`
- `AdaptiveButton.sfSymbol`
- `AdaptiveButton.icon`
- `AdaptiveButtonStyle.gray/tinted`
- `AdaptiveButtonSize.small/medium`
- `PlatformInfo.isIOS`

重構方向：

- 建立 `AppActionButton` 或直接改用 `FilledButton.tonal`, `TextButton`, `OutlinedButton`
- 將 style intent 轉換為 Material semantics：
  - `gray` → `FilledButton.tonal` 或 `TextButton`
  - `tinted` → `FilledButton.tonal`
  - `plain` → `TextButton`
- 移除 SF Symbol 分支

### 8. `lib/features/dictionary/presentation/widgets/entry_list_item.dart`

目前用途：

- `AdaptiveListTile`
- `PlatformInfo.isIOS`

重構方向：

- 直接替換成 `ListTile`
- trailing icon / size 改為單一 Material 寫法

### 9. `lib/features/dictionary/presentation/widgets/search_panel.dart`

目前用途：

- `AdaptiveTextField`
- `AdaptiveButton.sfSymbol`
- `AdaptiveButton.child`
- `AdaptiveButtonStyle.plain`
- `AdaptiveButtonSize.small`
- 多個 `PlatformInfo.isIOS` 分支

重構方向：

- 全面改成 `TextField`
- iOS 專屬 trailing clear button、prefix handling 改為單一 Material 版 `InputDecoration`
- 搜尋紀錄與 action chip 區塊內若還有 adaptive button，一併改成 `IconButton` / `TextButton`
- 這個檔案同時是互動最頻繁的頁面，建議列為第一批重構

### 10. `lib/features/dictionary/presentation/widgets/word_detail_sections.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptiveButton.child`
- `AdaptiveButtonStyle.plain`
- `PlatformInfo.isIOS`

重構方向：

- `AdaptiveListTile` → `ListTile`
- section 內的 plain actions 改成 `TextButton`
- 重新確認 iOS light-mode 專用分支是否仍有必要

### 11. `lib/features/settings/presentation/screens/about_app_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveFormSection.insetGrouped`
- 多個 `AdaptiveListTile`
- 多個 `PlatformInfo.isIOS`

重構方向：

- 這是 settings 系列中耦合最深的畫面之一
- 先建立 `AppSectionCard` 再遷移，否則重複樣板會很多
- 多個 section 可統一改成 `Card` + `Column` + `ListTile`

### 12. `lib/features/settings/presentation/screens/advanced_settings_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveFormSection.insetGrouped`
- 多個 `AdaptiveListTile`
- `PlatformInfo.isIOS`

重構方向：

- 結構與 settings 主畫面相近，可在 `AppSectionCard` 完成後平行遷移

### 13. `lib/features/settings/presentation/screens/license_overview_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveFormSection.insetGrouped`
- `AdaptiveListTile`
- `PlatformInfo.isIOS`

重構方向：

- 與 `about_app_screen.dart` 同類型
- 適合在 section/card 抽象完成後一併處理

### 14. `lib/features/settings/presentation/screens/license_summary_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveFormSection.insetGrouped`
- 多個 `AdaptiveListTile`
- `PlatformInfo.isIOS`

重構方向：

- 與 `license_overview_screen.dart` 同一批處理

### 15. `lib/features/settings/presentation/screens/reference_article_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `PlatformInfo.isIOS`

重構方向：

- 單純頁框替換即可，複雜度低

### 16. `lib/features/settings/presentation/screens/settings_screen.dart`

目前用途：

- `AdaptiveScaffold`
- `AdaptiveAppBar`
- `AdaptiveFormSection.insetGrouped`
- 多個 `AdaptiveListTile`
- `PlatformInfo.isIOS`

重構方向：

- settings 主畫面是另一個高優先入口
- 先完成這個檔案，其他 settings 子頁可以跟著使用同一套 section/tile 樣式

### 17. `lib/features/settings/presentation/widgets/audio_resource_tile.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptiveButton.sfSymbol`
- `AdaptiveButton.icon`
- `AdaptiveButtonStyle.plain`
- `AdaptiveButtonSize.small`
- `PlatformInfo.isIOS`

重構方向：

- `ListTile` + trailing `IconButton` / `TextButton.icon`
- 移除 iOS / Android 按鈕分叉

### 18. `lib/features/settings/presentation/widgets/dictionary_source_resource_tile.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptiveButton.sfSymbol`
- `AdaptiveButton.icon`
- `AdaptiveButtonStyle.plain`
- `AdaptiveButtonSize.small`
- `PlatformInfo.isIOS`

重構方向：

- 與 `audio_resource_tile.dart` 同步重構

### 19. `lib/features/settings/presentation/widgets/notification.dart`

目前用途：

- `AdaptiveSnackBar.show`
- `AdaptiveSnackBarType`

重構方向：

- 改為 `ScaffoldMessenger.of(context).showSnackBar(...)`
- 建立統一 helper，保留錯誤 / 資訊兩種樣式

### 20. `lib/features/settings/presentation/widgets/settings_locale_tile.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptivePopupMenuButton.icon`
- `AdaptivePopupMenuItem`
- `PlatformInfo.isIOS`

重構方向：

- `ListTile` + `PopupMenuButton<Locale>`
- icon 改為 Material icon，減少 iOS 分支

### 21. `lib/features/settings/presentation/widgets/settings_text_scale_tile.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptiveSlider`

重構方向：

- `ListTile` + `Slider`
- 複雜度低，可早期完成作為樣板

### 22. `lib/features/settings/presentation/widgets/settings_theme_mode_tile.dart`

目前用途：

- `AdaptiveListTile`
- `AdaptivePopupMenuButton.icon`
- `AdaptivePopupMenuItem`
- `PlatformInfo.isIOS`

重構方向：

- `ListTile` + `PopupMenuButton<AppThemePreference>`
- 既有「Apple 平台不顯示 AMOLED」邏輯需保留

### 23. `pubspec.yaml`

目前用途：

- `adaptive_platform_ui: 0.1.105`

重構方向：

- 所有 Flutter 呼叫點替換完成後移除此依賴
- 再執行 `flutter pub get`

## Recommended Migration Phases

### Phase 0: Branch And Baseline

建議分支名稱：

- `refactor/remove-adaptive-platform-ui`

基線驗證：

```bash
flutter analyze
flutter test
```

### Phase 1: App Shell And Global Helpers

處理檔案：

- `lib/app/app.dart`
- `lib/app/shell/main_shell.dart`
- `lib/core/utils/dialog_utils.dart`
- `lib/features/settings/presentation/widgets/notification.dart`

目標：

- App 根與主導航先脫離 adaptive 依賴
- 建立 Material 3 dialog / notification 基礎設施

### Phase 2: Common Building Blocks

處理檔案：

- 新增共用 `AppSectionCard`
- 新增共用 `AppActionButton`
- 新增共用 `AppMenuButton<T>`

目標：

- 將 settings / dictionary 內大量重複替換降到最低

### Phase 3: Settings Surfaces

處理檔案：

- `settings_screen.dart`
- `advanced_settings_screen.dart`
- `about_app_screen.dart`
- `license_summary_screen.dart`
- `license_overview_screen.dart`
- `reference_article_screen.dart`
- `settings_locale_tile.dart`
- `settings_text_scale_tile.dart`
- `settings_theme_mode_tile.dart`
- `audio_resource_tile.dart`
- `dictionary_source_resource_tile.dart`

目標：

- 完成 grouped sections 與 settings 行為遷移

### Phase 4: Dictionary And Bookmarks Surfaces

處理檔案：

- `dictionary_screen.dart`
- `word_detail_screen.dart`
- `bookmarks_screen.dart`
- `search_panel.dart`
- `audio_button.dart`
- `entry_list_item.dart`
- `word_detail_sections.dart`

目標：

- 移除互動最密集頁面的 adaptive button / text field / scaffold 依賴

### Phase 5: Cleanup

處理項目：

- 移除 `adaptive_platform_ui` import
- 移除 `PlatformInfo.isIOS` 的多餘分支
- 移除 `pubspec.yaml` 依賴
- 執行整體驗證

## Risks And Decisions To Make Up Front

1. **是否保留 iOS 特有 icon 語意**
   - 例如 `gearshape.fill`, `bookmark.fill`, `book.fill`
   - 若全面改 Material 3，建議統一改為 Material icons

2. **Grouped section 視覺風格要不要保留**
   - `AdaptiveFormSection.insetGrouped` 目前提供強烈 iOS grouped look
   - 若切換為純 Material 3，可接受畫面會更一致但不再像 iOS 設定頁

3. **Dialog 是否只用 Material `AlertDialog`**
   - 若完全捨棄 adaptive，dialog 在 iOS 上也應該統一成 Material 3

4. **Theme / locale popup 是否要升級成 `MenuAnchor`**
   - 功能上 `PopupMenuButton` 已足夠
   - 若只是完成遷移，先不要順便升級互動模型

5. **安全區與 top inset 的平台分叉是否保留**
   - 多數頁面可以用 `SafeArea` 與標準 `Scaffold` 解決
   - 建議在 Material 3 遷移後再逐步消除不必要手動 inset

## Validation Checklist

每個 phase 完成後至少檢查：

1. `flutter analyze`
2. `flutter test`
3. Android 模擬器 / 裝置手動檢查
4. Flutter iOS 畫面手動檢查
5. 深色 / 淺色主題切換
6. 語言切換
7. 搜尋、書籤、設定、離線資源、dialog、通知功能

最終移除依賴前再執行：

```bash
flutter pub get
flutter analyze
flutter test
```

並確認以下命令沒有結果：

```bash
rg "adaptive_platform_ui|Adaptive[A-Z]|PlatformInfo\.isIOS" lib pubspec.yaml
```

## Recommended First Concrete Slice

如果要用最小風險開始，建議第一刀不是直接改 settings，而是：

1. `lib/app/app.dart`
2. `lib/app/shell/main_shell.dart`
3. `lib/features/settings/presentation/widgets/notification.dart`
4. `lib/core/utils/dialog_utils.dart`

理由：

- 這四個檔案可以先建立 Material 3 的基本框架與共用 helper
- 一旦這層穩定，後續頁面替換會更機械化
- 也是最容易看出是否有全域視覺回歸問題的一批
