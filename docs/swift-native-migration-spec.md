# Taigi Dict Swift Native Migration Specification

本文根據目前 Flutter 專案實作整理，作為後續以 Swift / SwiftUI 完全重構時的唯一依據。  
分析基準主要來自：

- [lib/app/shell/main_shell.dart](/Users/emik/Documents/Hokkien/lib/app/shell/main_shell.dart:1)
- [lib/app/initialization/app_initialization_controller.dart](/Users/emik/Documents/Hokkien/lib/app/initialization/app_initialization_controller.dart:1)
- [lib/features/dictionary/data/dictionary_repository.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/data/dictionary_repository.dart:1)
- [lib/features/dictionary/data/dictionary_database_builder_service.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/data/dictionary_database_builder_service.dart:1)
- [lib/features/dictionary/application/dictionary_search_controller.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/application/dictionary_search_controller.dart:1)
- [lib/features/audio/data/offline_audio_library.dart](/Users/emik/Documents/Hokkien/lib/features/audio/data/offline_audio_library.dart:1)
- [lib/features/dictionary/presentation/screens/dictionary_screen.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/screens/dictionary_screen.dart:1)
- [lib/features/dictionary/presentation/coordinators/word_detail_coordinator.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/coordinators/word_detail_coordinator.dart:1)
- [lib/features/settings/presentation/screens/settings_screen.dart](/Users/emik/Documents/Hokkien/lib/features/settings/presentation/screens/settings_screen.dart:1)

## 實作狀態註記（2026-05-01）

本文件最初用於規劃 Swift 原生重寫；截至 2026-05-01，多數核心行為已在 `ios-native/` 中落地。為避免後續重複盤點，先記錄本次複審結論：

- 已完成：初始化阻塞流程、JSONL/manifest 匯入、SQLite schema、搜尋 normalization 與排序、搜尋歷史、書籤、alias resolve、OpenCC 簡繁轉換、離線音訊下載與播放、設定頁、關於/授權/參考資料頁、iPad `NavigationSplitView`。
- 已完成但先前文件較容易誤判：ODS 轉 JSONL 的 build-time 轉換工具已存在於 `tool/build_dictionary_asset.py`；原生 app 也已在 `ios-native/NativeApp/TaigiDictNativeApp.swift` 注入 bundled dictionary source。
- 主要尚未補齊的是測試矩陣中的 integration tests 與 UI snapshot targets；這屬於驗證層缺口，不是核心功能缺口。

閱讀本文件時，應將第 1～4 章視為「行為與架構依據」，不是代表目前仍然全部待實作。

## 1. 核心業務邏輯 (Core Business Logic)

### 1.1 App 定位

- App 是離線優先的台語辭典。
- 上游原始資料是教育部 `kautian.ods`，但 Swift App 不直接讀 ODS。
- Swift 版需要在 build time、release pipeline 或後台先把 ODS 預轉換成 JSON/JSONL 或 CSV 中介格式。
- 實際查詢介面主要依賴本機 SQLite。
- App 支援詞目音檔與例句音檔的離線下載與播放。
- App 支援繁中、簡中、英文介面。

### 1.2 啟動初始化流程

- 啟動時初始化：
  - `AppPreferences`
  - `LocaleProvider`
  - `ChineseTranslationService`
  - `OfflineAudioLibrary`
  - `BookmarkStore`
  - `OfflineDictionaryLibrary`
  - `AppInitializationController`
- 初始化是阻塞式。
- 若本機 SQLite 未就緒，App 停留在初始化畫面，不能進入主功能。
- 初始化 controller 會：
  - 檢查預轉換資料包是否存在
  - 必要時恢復內建預轉換資料包
  - 必要時下載遠端預轉換資料包
  - 判斷 SQLite 是否存在與是否需要 rebuild
  - 讀取預轉換資料並重建 SQLite
  - 寫入 `is_db_ready`

### 1.3 Dictionary Source / Database

- 上游 ODS 檔名：`kautian.ods`
- Swift App 內不直接解析 `kautian.ods`。
- 建議主要中介格式：`dictionary_entries.jsonl` + `dictionary_manifest.json`
- 可選交換格式：CSV 多表輸出，但不建議作為 App 內主要讀取格式。
- DB 檔名：`dictionary.sqlite`
- 現有 Flutter ODS 下載 URL：
  - `https://app.taigidict.org/assets/kautian.ods`
- Swift 版應改為下載預轉換資料包，例如：
  - `https://app.taigidict.org/assets/dictionary-json-v1.zip`
  - 或直接下載預建 `dictionary.sqlite`
- Swift 版應內建一份預轉換資料包或預建 SQLite。
- 若下載檔案缺失或大小為 0，會被視為 invalid 並刪除。
- DB rebuild 判定條件：
  - DB 不存在
  - DB schema 不完整
  - 預轉換資料包版本或 modified time 比 DB 新

### 1.4 預轉換資料規格

- ODS 的解析應發生在 Flutter/Dart 工具、Python 腳本、CI pipeline 或後台轉換程序中，不應放在 Swift App runtime。
- 預轉換器仍需讀取 ODS 的必要 sheet：
  - `詞目`
  - `義項`
  - `例句`
- 預轉換器仍需讀取 ODS 的可選 sheet：
  - `異用字`
  - `義項tuì義項近義`
  - `義項tuì義項反義`
  - `義項tuì詞目近義`
  - `義項tuì詞目反義`
  - `詞目tuì詞目近義`
  - `詞目tuì詞目反義`
  - `又唸作`
  - `合音唸作`
  - `俗唸作`
  - `語音差異`
  - `詞彙比較`
- 若必要 sheet 缺失，預轉換程序應失敗並輸出明確錯誤。
- 若 ODS 為空或不可解析，預轉換程序應失敗並避免產生 release artifact。

#### 建議 JSONL 格式

- `dictionary_manifest.json`
  - `formatVersion`
  - `sourceFileName`
  - `sourceModifiedAt`
  - `builtAt`
  - `entryCount`
  - `senseCount`
  - `exampleCount`
  - `checksum`
- `dictionary_entries.jsonl`
  - 每行是一個完整 `DictionaryEntry` JSON object。
  - 內含 `senses` 與 `examples`，避免 Swift runtime 再做多表 join。
  - Swift rebuild SQLite 時逐行 streaming decode，降低記憶體峰值。

#### 建議 JSON entry shape

```json
{
  "id": 1,
  "type": "主詞目",
  "hanji": "辭典",
  "romanization": "sû-tián",
  "category": "教育、學術",
  "audioId": "1(1)",
  "variantChars": [],
  "wordSynonyms": ["字典"],
  "wordAntonyms": [],
  "alternativePronunciations": [],
  "contractedPronunciations": [],
  "colloquialPronunciations": [],
  "phoneticDifferences": [],
  "vocabularyComparisons": [],
  "aliasTargetEntryId": null,
  "hokkienSearch": "辭典 su tian",
  "mandarinSearch": "一種工具書",
  "senses": [
    {
      "partOfSpeech": "名詞",
      "definition": "一種工具書。",
      "definitionSynonyms": ["字典"],
      "definitionAntonyms": [],
      "examples": [
        {
          "hanji": "辭典是真重要的工具冊。",
          "romanization": "Sû-tián sī tsin tiōng-iàu ê kang-kū-tsheh.",
          "mandarin": "辭典是很重要的工具書。",
          "audioId": "1-1-1"
        }
      ]
    }
  ]
}
```

#### CSV 選項

- 若需要 CSV，應輸出多個 CSV：
  - `entries.csv`
  - `senses.csv`
  - `examples.csv`
  - `metadata.csv`
- 陣列欄位仍需 JSON-encoded string。
- CSV 對 Swift runtime streaming 解析也可行，但 JSONL 更能保留巢狀結構與型別語意。

### 1.5 Dictionary 資料模型

#### `DictionaryBundle`

- `entryCount: Int`
- `senseCount: Int`
- `exampleCount: Int`
- `entries: [DictionaryEntry]`
- `databasePath: String?`
- `isDatabaseBacked: Bool`

#### `DictionaryEntry`

- `id: Int`
- `type: String`
- `hanji: String`
- `romanization: String`
- `category: String`
- `audioId: String`
- `hokkienSearch: String`
- `mandarinSearch: String`
- `variantChars: [String]`
- `wordSynonyms: [String]`
- `wordAntonyms: [String]`
- `alternativePronunciations: [String]`
- `contractedPronunciations: [String]`
- `colloquialPronunciations: [String]`
- `phoneticDifferences: [String]`
- `vocabularyComparisons: [String]`
- `aliasTargetEntryId: Int?`
- `senses: [DictionarySense]`

衍生規則：

- `redirectsToPrimaryEntry = aliasTargetEntryId != nil`
- `briefSummary` 取值順序：
  - 第一個非空 `sense.definition`
  - `category`
  - `type`
  - `romanization`
  - alias entry 的 summary 直接為空

#### `DictionarySense`

- `partOfSpeech: String`
- `definition: String`
- `definitionSynonyms: [String]`
- `definitionAntonyms: [String]`
- `examples: [DictionaryExample]`

#### `DictionaryExample`

- `hanji: String`
- `romanization: String`
- `mandarin: String`
- `audioId: String`

### 1.6 SQLite Schema

#### `dictionary_entries`

- `id INTEGER PRIMARY KEY`
- `type TEXT NOT NULL`
- `hanji TEXT NOT NULL`
- `romanization TEXT NOT NULL`
- `category TEXT NOT NULL`
- `audio_id TEXT NOT NULL`
- `variant_chars TEXT NOT NULL`
- `word_synonyms TEXT NOT NULL`
- `word_antonyms TEXT NOT NULL`
- `alternative_pronunciations TEXT NOT NULL`
- `contracted_pronunciations TEXT NOT NULL`
- `colloquial_pronunciations TEXT NOT NULL`
- `phonetic_differences TEXT NOT NULL`
- `vocabulary_comparisons TEXT NOT NULL`
- `alias_target_entry_id INTEGER`
- `hokkien_search TEXT NOT NULL`
- `mandarin_search TEXT NOT NULL`

#### `dictionary_senses`

- `entry_id INTEGER NOT NULL`
- `sense_id INTEGER NOT NULL`
- `part_of_speech TEXT NOT NULL`
- `definition TEXT NOT NULL`
- `definition_synonyms TEXT NOT NULL`
- `definition_antonyms TEXT NOT NULL`
- 主鍵 `(entry_id, sense_id)`

#### `dictionary_examples`

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `entry_id INTEGER NOT NULL`
- `sense_id INTEGER NOT NULL`
- `example_order INTEGER NOT NULL`
- `hanji TEXT NOT NULL`
- `romanization TEXT NOT NULL`
- `mandarin TEXT NOT NULL`
- `audio_id TEXT NOT NULL`

#### `dictionary_metadata`

- `key TEXT PRIMARY KEY`
- `value TEXT NOT NULL`

#### 既有 index

- `idx_entries_hokkien_search`
- `idx_entries_mandarin_search`
- `idx_senses_entry_id`
- `idx_examples_entry_sense_order`

### 1.7 搜尋功能

- 支援搜尋：
  - 台語漢字
  - 白話字 / 羅馬字
  - 華語釋義
  - 例句中的漢字與華語
- 搜尋 query 會先 normalization：
  - trim
  - 小寫
  - 去 tone diacritics
  - 去數字調號 `1-8`
  - `o͘ -> oo`
  - `ⁿ -> n`
  - `-_/` 視為空白
  - 去除括號與標點
  - 合併多個空白
- 排序規則：
  - `hanji == query` 優先
  - `hokkien_search LIKE query` 或 `hanji LIKE query` 次之
  - definition / example 命中再次之
  - 再依 `length(hokkien_search)` 較短優先
  - 最後依 `id`
- 返回上限為 60 筆。

### 1.8 搜尋歷史

- 儲存在 `SharedPreferences` key：`recent_search_history`
- 上限 10 筆
- 僅在查詢有結果時保存
- 新查詢置頂
- 重複查詢會去重後置頂

### 1.9 書籤

- 儲存在 `SharedPreferences` key：`bookmarked_entry_ids`
- 只存 `entryId`
- toggle 行為：
  - 已存在則移除
  - 不存在則插到最前面
- 畫面展示前會做排序與重新查表

### 1.10 Alias / Linked Entry 規則

- 某些 entry 只是指向主詞條的 proxy。
- `aliasTargetEntryId` 非空表示需 resolve。
- detail 開啟前會一直追 alias chain，直到主詞條。
- 為避免循環，會記錄 visited ids。
- linked entry 查找時：
  - exact hanji 優先
  - variant char 次之
  - romanization 最後
  - 不以 mandarin 當 linked entry 的 direct lookup key

### 1.11 簡繁轉換

- interface locale 支援：
  - `en`
  - `zh-CN`
  - `zh-TW`
- Swift 重構版需使用 `PhoenixEmik/SwiftyOpenCC`：
  - Swift Package URL：`https://github.com/PhoenixEmik/SwiftyOpenCC.git`
  - import module：`OpenCC`
  - 以 `ChineseConverter` 建立轉換器
- 若 locale 為簡中：
  - 搜尋輸入先用 SwiftyOpenCC 做等價 `S2TWp` 流程，轉為台灣繁體再查詢。
  - 顯示用字再用 SwiftyOpenCC 做等價 `TW2Sp` 流程，轉為簡體顯示。
- 僅對包含漢字且 surrogate 完整的字串做轉換。
- 對 romanization-only query 不做轉換。
- 第三方 API 不可散落在 view / repository 中；必須集中於 `ChineseConversionService` 或其 adapter。

### 1.12 音訊下載與播放

- archive 類型：
  - `word`
  - `sentence`
- 檔案：
  - `sutiau-mp3.zip`
  - `leku-mp3.zip`
- 下載 URL：
  - `https://app.taigidict.org/assets/sutiau-mp3.zip`
  - `https://app.taigidict.org/assets/leku-mp3.zip`
- archive 下載支援：
  - 開始
  - 暫停
  - 續傳
  - 重新下載
- 實作不是整包解壓：
  - 先建立 zip entry index
  - 播放某 clip 時只 materialize 該 mp3 到 cache
- 正在播放同一 clip 再點一次會 stop。

### 1.13 設定與靜態內容

- 偏好項：
  - 語言
  - 主題模式
  - 閱讀字級
- 維護項：
  - 重下載預轉換詞典資料包
  - 重下載詞目音檔
  - 重下載例句音檔
  - 強制重建 dictionary DB
- 靜態資訊：
  - 臺羅標注說明
  - 漢字用字原則
  - 隱私政策
  - 關於頁
  - 授權資訊
  - Flutter / package licenses

## 2. 狀態管理機制 (State Management Analysis)

### 2.1 Flutter 目前的狀態管理方式

- 沒有使用 Provider / Riverpod / BLoC。
- 主要組合是：
  - `ChangeNotifier`
  - `InheritedNotifier`
  - `StatefulWidget + setState`
  - `FutureBuilder`
  - `AnimatedBuilder`
  - `ListenableBuilder`
  - `ValueListenableBuilder`

### 2.2 全域 / 應用級狀態

#### `AppPreferences`

- `readingTextScale`
- `themePreference`
- `materialThemeMode`
- `useAmoledTheme`

#### `LocaleProvider`

- `locale`

#### `BookmarkStore`

- `_bookmarkedIds`

#### `OfflineDictionaryLibrary`

- `_initialized`
- `_initializationFailed`
- `_sourceReady`
- `downloadSnapshot`

#### `OfflineAudioLibrary`

- `_indexes`
- `_isReady`
- `_loadingClipKey`
- `_playingClipKey`
- 各 archive 的 `DownloadSnapshot`

### 2.3 啟動與初始化狀態

#### `AppInitializationController`

- `_phase`
- `_error`
- `_buildProgress`
- `_activeOperation`
- `_databaseGeneration`

衍生狀態：

- `isReady`
- `isRunning`
- `progress`
- `processedUnits`
- `totalUnits`

### 2.4 Dictionary 搜尋狀態

#### `DictionarySearchController`

- `searchController.text`
- `bundleFuture`
- `_bundle`
- `_filteredResults`
- `_searchHistory`
- `_normalizedQuery`
- `_isSearching`
- `_searchRequestId`
- `_searchDebounceTimer`
- `_initialized`
- `_displayLocale`

### 2.5 頁面局部狀態

#### `MainScreen`

- `_selectedIndex`
- `_cachedScreenGeneration`
- `_cachedScreens`
- `_startupRequested`

#### `DictionaryScreen`

- `_lastResolvedLocale`
- `_cachedBundle`
- `_selectedTabletSourceEntry`
- `_selectedTabletDetail`
- `_isLoadingTabletDetail`
- `_tabletSelectionToken`

#### `BookmarksScreen`

- `_bundleFuture`
- `_entriesFuture`
- `_entriesFutureKey`
- `_cachedBundle`
- `_entriesCacheByKey`
- `_displayLocale`

### 2.6 狀態行為上的隱性需求

- locale 改變時，搜尋結果與 bookmark 條目需要重新轉換顯示文字。
- 搜尋要防止 async 舊結果覆蓋新結果。
- rebuild DB 後必須 invalidation dictionary screen / bookmark screen cache。
- split view detail 選取需要防 race condition，因此用 token。

## 3. UI 畫面清單與互動 (UI Screens & Interactions)

### 3.1 App Initialization Screen

關鍵元件：

- 標題
- 階段說明文
- 細節文案
- `LinearProgressIndicator`
- Retry button

互動流程：

1. App 啟動。
2. 顯示初始化卡片。
3. 依 phase 更新文案與進度。
4. 若 error，顯示 Retry。
5. Ready 後切到 main shell。

### 3.2 Main Shell

關鍵元件：

- Bottom tab bar
- `Dictionary`
- `Bookmarks`
- `Settings`

互動流程：

1. 完成初始化後進主殼層。
2. 使用者切 tab。
3. 每個 tab 保持自己的 state。

### 3.3 Dictionary Screen

關鍵元件：

- 搜尋框
- 搜尋歷史卡
- 搜尋中指示器
- Empty state
- No result state
- 結果列表
- 平板 split view detail pane

互動流程：

1. 輸入文字。
2. 若非空，停頓 300ms 後搜尋。
3. 若空字串，立即清掉結果。
4. 搜尋中顯示 progress。
5. 搜尋完成更新 list。
6. 點詞條：
   - 手機 push detail
   - 平板更新右側 pane
7. 點歷史記錄 chip 立即回填並搜尋。
8. 點清除搜尋按鈕清空查詢。
9. 點清除歷史按鈕刪除全部歷史。

### 3.4 Word Detail Screen

關鍵元件：

- App bar title
- Share button
- Bookmark button
- Header card
- Audio button
- Part-of-speech pill
- Definition rich text
- Example cards
- Variant / synonym / antonym chips
- Phonetic differences card
- Vocabulary comparison card

互動流程：

1. 進入 detail 時先 resolve alias。
2. 顯示 localized entry。
3. 點 audio 播放詞目或例句。
4. 點書籤切換 bookmark。
5. 點分享呼叫系統 share sheet。
6. 點 chip 或 `【詞】` 連結，導航到 linked entry。

### 3.5 Bookmarks Screen

關鍵元件：

- 空狀態
- 書籤 list
- 平板 grid

互動流程：

1. 讀 bookmark ids。
2. 反查 entries。
3. 依 locale 做 display translation。
4. 點擊 entry 開 detail。

### 3.6 Settings Screen

區塊：

- Offline Resources
- Appearance
- About

關鍵元件：

- resource tiles with progress
- locale picker
- theme picker
- text scale slider
- advanced settings entry
- reference article entries
- about entry

### 3.7 Advanced Settings Screen

功能：

- redownload dictionary source
- redownload word audio archive
- redownload sentence audio archive
- rebuild dictionary DB

互動流程：

1. 點某維護動作。
2. 顯示 confirmation dialog。
3. 執行動作。
4. rebuild 時顯示 blocking progress dialog。
5. 以 app notification 顯示結果。

### 3.8 About / License / Reference Screens

- About App：版本、作者、repo、隱私政策、授權入口、參考連結
- License Summary：MIT / dictionary data / audio / Flutter licenses
- License Overview：列出 package license groups
- Reference Article：渲染段落、bullet、table

## 4. Swift/SwiftUI 遷移策略建議 (Migration Strategy to iOS Native)

### 4.1 基本原則

- 第一階段目標應是功能 parity，而不是結構創新。
- 優先保留：
  - SQLite schema
  - 搜尋 normalization
  - alias resolve
  - SwiftyOpenCC-backed OpenCC 流程
  - 離線音訊 zip index 策略
- 先保留資料與流程語意，再考慮第二階段優化。

### 4.2 資料庫建議

- 建議使用 `GRDB`。
- 原因：
  - 最接近現有 SQLite 設計
  - 容易手寫 migration
  - 容易維持 raw SQL 搜尋排序
  - 對批次匯入與 read-only query 友善

不建議第一階段使用：

- SwiftData
- Core Data

因為：

- 現有 schema 已很具體
- 需要大量自訂 SQL
- rebuild / metadata / schema check 都比較像資料庫工具工作，不像典型 object graph

### 4.3 詞典資料重建策略

- Swift runtime 不應直接解析 ODS。
- 上游 ODS 應先透過轉換工具產生 JSONL/CSV 或預建 SQLite。
- 推薦兩種策略：

- JSONL rebuild 策略：
  - App 內建或下載 `dictionary-json-v1.zip`
  - zip 內含 `dictionary_manifest.json` 與 `dictionary_entries.jsonl`
  - App streaming decode JSONL 並寫入 SQLite
  - 功能 parity 高，且 Swift 端不需 ODS parser
- 預建 SQLite 策略：
  - CI 或後台直接產生 `dictionary.sqlite`
  - App 只下載並替換 SQLite
  - runtime 成本最低，但 App 端 rebuild progress 較粗

第一版建議採 JSONL rebuild 策略；若上架包體與更新流程允許，可再升級為預建 SQLite。

### 4.4 狀態管理對應

- `ChangeNotifier` -> `@Observable`
- `InheritedNotifier scope` -> `Environment` 注入 observable store
- `FutureBuilder` -> `task`, `async let`, `phase enum`
- `AnimatedBuilder` -> SwiftUI 自動觀察 `@Observable`
- `setState` 局部狀態 -> `@State`

### 4.5 持久化對應

- `SharedPreferences` -> `UserDefaults`
- 建議把 key 常數集中到 `AppStorageKeys`
- 支援項：
  - `interface_locale`
  - `theme_preference`
  - `reading_text_scale`
  - `recent_search_history`
  - `bookmarked_entry_ids`
  - `is_db_ready`

### 4.6 中文轉換建議

- 建議使用 `PhoenixEmik/SwiftyOpenCC`，不要自行在 app target 內包 Objective-C / C++ OpenCC bridge。
- Swift Package：
  - URL：`https://github.com/PhoenixEmik/SwiftyOpenCC.git`
  - 模組：`OpenCC`
  - 主要型別：`ChineseConverter`
- 建議把套件 pin 到 release tag 或固定 commit，避免 CI 在套件 API 變動時產生不可重現 build。
- 實作一個 `ChineseConversionService` actor：
  - `normalizeSearchInput(text:locale:)`
  - `translateForDisplay(text:locale:)`
  - 內部持有 SwiftyOpenCC converter instance
  - 搜尋輸入保留原 Flutter OpenCC `S2TWp` 語意
  - 簡中顯示保留原 Flutter OpenCC `TW2Sp` 語意
  - LRU cache
  - in-flight de-dup
- 介面建議：

```swift
import OpenCC

protocol ChineseConversionProviding: Sendable {
    func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String
    func translateForDisplay(_ text: String, locale: AppLocale) async -> String
}
```

- adapter 內必須保留輸入 guard：
  - 不含漢字時直接回傳原字串。
  - surrogate 不完整或轉換失敗時回傳原字串。
  - 不得因簡繁轉換失敗阻斷搜尋或 detail rendering。

### 4.7 音訊與下載建議

- 下載：
  - `URLSession`
  - 保留 `Range` header 續傳
- 播放：
  - `AVAudioPlayer` 可先滿足本地 mp3 播放
- zip index：
  - `ZIPFoundation`
  - 保留「只抽單檔 clip，不整包解壓」

### 4.8 UI 元件對應

| Flutter 元件 | SwiftUI 對應 |
|---|---|
| `AdaptiveScaffold` | `NavigationStack`, `TabView`, `NavigationSplitView` |
| 搜尋框 | `TextField` 或 `.searchable` |
| `Card` | `RoundedRectangle` + `background` + `overlay` |
| `AdaptiveListTile` | `Button` + `HStack/VStack` |
| `LinearProgressIndicator` | `ProgressView(value:)` |
| `ActionChip` / pill | `Button` with capsule style |
| `FutureBuilder` | `task` + phase state |
| `AnimatedSwitcher` | `if/else` + `.transition()` |
| share sheet | `ShareLink` 或 `UIActivityViewController` bridge |

### 4.9 建議的 iPad 佈局

- Dictionary：`NavigationSplitView`
- Bookmarks：`LazyVGrid`
- Settings：雙欄 `ScrollView + HStack`

### 4.10 不可丟失的行為

- 搜尋 300ms debounce
- 清空 query 時立即清空結果
- 只在有結果時保存 history
- romanization normalization 規則完整保留
- alias resolve 保留
- linked entry 排除導回自己
- 簡體 query 先轉繁搜尋
- rebuild 成功後 cache invalidation
- 音訊下載可 pause/resume

## 5. Swift 原生專案藍圖 (Next Step Blueprint)

### 5.1 建議檔案樹

```text
TaigiDict/
  App/
    TaigiDictApp.swift
    AppCoordinator.swift
    AppEnvironment.swift
  Core/
    Constants/
      AppConstants.swift
      AppStorageKeys.swift
    Localization/
      AppLocale.swift
      LocaleResolver.swift
    Preferences/
      AppSettingsStore.swift
      LocaleStore.swift
    Utilities/
      AsyncDebouncer.swift
      NotificationBannerModel.swift
  Data/
    Database/
      DatabaseManager.swift
      DictionaryMigrations.swift
      DictionaryRecord.swift
      SenseRecord.swift
      ExampleRecord.swift
      MetadataRecord.swift
    Import/
      DictionaryImportService.swift
      DictionaryJSONLReader.swift
      DictionaryManifest.swift
      DictionaryImportModels.swift
    Repositories/
      DictionaryRepository.swift
      BookmarkRepository.swift
      PreferencesRepository.swift
    Audio/
      AudioArchiveDescriptor.swift
      AudioArchiveStore.swift
      AudioZipIndexService.swift
      AudioPlaybackService.swift
    Network/
      ResumableDownloadService.swift
  Domain/
    Models/
      DictionaryBundle.swift
      DictionaryEntry.swift
      DictionarySense.swift
      DictionaryExample.swift
      PreparedWordDetail.swift
      DownloadSnapshot.swift
    Services/
      DictionarySearchService.swift
      ChineseConversionService.swift
      LinkedEntryResolver.swift
      ShareTextBuilder.swift
  Features/
    Initialization/
      InitializationViewModel.swift
      InitializationView.swift
    Dictionary/
      DictionarySearchViewModel.swift
      DictionaryScreen.swift
      DictionarySplitView.swift
      SearchBarView.swift
      SearchHistoryView.swift
      EntryRowView.swift
    WordDetail/
      WordDetailViewModel.swift
      WordDetailScreen.swift
      WordDetailHeaderView.swift
      SenseSectionView.swift
      ExampleCardView.swift
      RelationshipChipView.swift
    Bookmarks/
      BookmarkStore.swift
      BookmarksViewModel.swift
      BookmarksScreen.swift
    Settings/
      SettingsViewModel.swift
      SettingsScreen.swift
      AdvancedSettingsScreen.swift
      AboutScreen.swift
      LicenseSummaryScreen.swift
      LicenseOverviewScreen.swift
      ReferenceArticleScreen.swift
```

### 5.2 建議的 `@Observable` ViewModel 邊界

#### `AppSettingsStore`

- `var readingTextScale: Double`
- `var themePreference: AppThemePreference`
- `var effectiveColorScheme: ColorScheme?`
- functions:
  - `load()`
  - `setThemePreference(_:)`
  - `setReadingTextScale(_:)`

#### `LocaleStore`

- `var localeOverride: AppLocale?`
- `var resolvedLocale: AppLocale`
- functions:
  - `load()`
  - `setLocale(_:)`
  - `clearLocalePreference()`

#### `InitializationViewModel`

- `var phase: InitializationPhase`
- `var progress: Double?`
- `var processedUnits: Int`
- `var totalUnits: Int`
- `var errorMessage: String?`
- `var isReady: Bool`
- `var databaseGeneration: Int`
- functions:
  - `start()`
  - `retry()`
  - `rebuild()`

#### `DictionarySearchViewModel`

- `var searchText: String`
- `var normalizedQuery: String`
- `var isSearching: Bool`
- `var results: [DictionaryEntry]`
- `var searchHistory: [String]`
- `var selectedTabletEntryID: Int?`
- `var selectedTabletDetail: PreparedWordDetail?`
- `var isLoadingTabletDetail: Bool`
- functions:
  - `loadBundle()`
  - `scheduleSearch()`
  - `runSearchImmediately(saveHistoryIfValid:)`
  - `applyHistoryQuery(_:)`
  - `clearSearchHistory()`
  - `selectEntry(_:)`

#### `WordDetailViewModel`

- `var entry: DictionaryEntry`
- `var resolvedEntryID: Int`
- `var openableWords: Set<String>`
- `var isBookmarked: Bool`
- `var loadingClipKey: String?`
- `var playingClipKey: String?`
- functions:
  - `prepare(entry:)`
  - `toggleBookmark()`
  - `playWordAudio()`
  - `playExampleAudio(_:)`
  - `openLinkedWord(_:)`
  - `buildShareText()`

#### `BookmarkStore`

- `var bookmarkedIDs: [Int]`
- functions:
  - `load()`
  - `toggle(_ id: Int)`
  - `contains(_ id: Int)`

#### `BookmarksViewModel`

- `var entries: [DictionaryEntry]`
- `var isLoading: Bool`
- `var isEmpty: Bool`
- functions:
  - `loadBookmarks()`
  - `reloadForLocaleChange()`

#### `OfflineDictionaryResourceStore`

- `var isSourceReady: Bool`
- `var snapshot: DownloadSnapshot`
- `var fileName: String`
- functions:
  - `initialize()`
  - `downloadOrPause()`
  - `restoreBundledSourceIfMissing()`
  - `invalidateSource()`

#### `OfflineAudioStore`

- `var wordArchiveSnapshot: DownloadSnapshot`
- `var sentenceArchiveSnapshot: DownloadSnapshot`
- `var wordArchiveReady: Bool`
- `var sentenceArchiveReady: Bool`
- `var loadingClipKey: String?`
- `var playingClipKey: String?`
- functions:
  - `initialize()`
  - `downloadArchive(_:)`
  - `pauseArchive(_:)`
  - `invalidateArchive(_:)`
  - `playClip(type:id:)`

#### `SettingsViewModel`

- `var selectedLocale: AppLocale`
- `var themePreference: AppThemePreference`
- `var textScale: Double`
- `var dictionarySnapshot: DownloadSnapshot`
- `var wordAudioSnapshot: DownloadSnapshot`
- `var sentenceAudioSnapshot: DownloadSnapshot`
- functions:
  - `downloadDictionarySource()`
  - `downloadArchive(_:)`
  - `rebuildDictionaryDatabase()`

### 5.3 建議的 GRDB Migration 草案

```swift
import GRDB

enum DictionaryMigrations {
    static func register(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_dictionary_schema") { db in
            try db.create(table: "dictionary_entries") { t in
                t.column("id", .integer).primaryKey()
                t.column("type", .text).notNull()
                t.column("hanji", .text).notNull()
                t.column("romanization", .text).notNull()
                t.column("category", .text).notNull()
                t.column("audio_id", .text).notNull()
                t.column("variant_chars", .text).notNull()
                t.column("word_synonyms", .text).notNull()
                t.column("word_antonyms", .text).notNull()
                t.column("alternative_pronunciations", .text).notNull()
                t.column("contracted_pronunciations", .text).notNull()
                t.column("colloquial_pronunciations", .text).notNull()
                t.column("phonetic_differences", .text).notNull()
                t.column("vocabulary_comparisons", .text).notNull()
                t.column("alias_target_entry_id", .integer)
                t.column("hokkien_search", .text).notNull()
                t.column("mandarin_search", .text).notNull()
            }

            try db.create(table: "dictionary_senses") { t in
                t.column("entry_id", .integer).notNull()
                t.column("sense_id", .integer).notNull()
                t.column("part_of_speech", .text).notNull()
                t.column("definition", .text).notNull()
                t.column("definition_synonyms", .text).notNull()
                t.column("definition_antonyms", .text).notNull()
                t.primaryKey(["entry_id", "sense_id"])
            }

            try db.create(table: "dictionary_examples") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("entry_id", .integer).notNull()
                t.column("sense_id", .integer).notNull()
                t.column("example_order", .integer).notNull()
                t.column("hanji", .text).notNull()
                t.column("romanization", .text).notNull()
                t.column("mandarin", .text).notNull()
                t.column("audio_id", .text).notNull()
            }

            try db.create(table: "dictionary_metadata") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
            }

            try db.create(index: "idx_entries_hokkien_search", on: "dictionary_entries", columns: ["hokkien_search"])
            try db.create(index: "idx_entries_mandarin_search", on: "dictionary_entries", columns: ["mandarin_search"])
            try db.create(index: "idx_senses_entry_id", on: "dictionary_senses", columns: ["entry_id"])
            try db.create(index: "idx_examples_entry_sense_order", on: "dictionary_examples", columns: ["entry_id", "sense_id", "example_order"])
        }
    }
}
```

### 5.4 建議的 Search Service 介面

```swift
protocol DictionarySearchServiceProtocol {
    func normalizeQuery(_ input: String) -> String
    func search(query: String, limit: Int, offset: Int) async throws -> [DictionaryEntry]
    func findLinkedEntry(for word: String) async throws -> DictionaryEntry?
    func entries(ids: [Int]) async throws -> [DictionaryEntry]
    func entry(id: Int) async throws -> DictionaryEntry?
}
```

### 5.5 建議的重構階段

#### Phase 1

- 建立 App shell
- 建立 SQLite 讀取
- 完成 dictionary search
- 完成 detail / bookmark / settings 基本頁面

#### Phase 2

- 完成 SwiftyOpenCC-backed 顯示與查詢轉換
- 完成 iPad split view
- 完成搜尋歷史與書籤持久化

#### Phase 3

- 完成 JSONL/CSV 詞典資料包 rebuild
- 完成 archive 下載 / pause / resume
- 完成 zip single clip extraction

#### Phase 4

- 完成 reference / license / privacy screens
- 視覺與互動 polish
- 測試與效能收斂

### 5.6 後續 AI Agent 的執行約束

- 不可改變搜尋 normalization 規則。
- 不可改變搜尋排序規則。
- 不可刪除 alias resolve。
- 不可把簡體轉換直接改成 UI 層字串替換。
- 不可把音訊 archive 改成整包解壓為預設行為。
- 第一版不可用 SwiftData 取代 SQLite/GRDB。
