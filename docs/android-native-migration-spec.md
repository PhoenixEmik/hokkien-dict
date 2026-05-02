# Taigi Dict Android Native Migration Specification

本文根據目前 Flutter 專案實作與既有 iOS native 重寫結果整理，作為後續以 Kotlin / Jetpack Compose 完全重構時的主要依據。

分析基準主要來自：

- `lib/app/shell/main_shell.dart`
- `lib/app/initialization/app_initialization_controller.dart`
- `lib/features/dictionary/data/dictionary_repository.dart`
- `lib/features/dictionary/data/dictionary_database_builder_service.dart`
- `lib/features/dictionary/application/dictionary_search_controller.dart`
- `lib/features/audio/data/offline_audio_library.dart`
- `lib/features/dictionary/presentation/screens/dictionary_screen.dart`
- `lib/features/dictionary/presentation/coordinators/word_detail_coordinator.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `ios-native/README.md`
- `docs/ios-native-migration-spec.md`
- `docs/ios-native-implementation-plan.md`

## 實作狀態註記（2026-05-02）

目前 `android-native/` 尚未建立可開發的 Android app 專案骨架，也尚未有等價於 iOS native 的產品實作。因此本文件不是既有 Android 程式碼的摘要，而是供 Android native 開發啟動時使用的約束文件。

本文件的角色如下：

- 固定產品行為，避免 Android 版在開發初期自行漂移。
- 把 Flutter 與 iOS native 已確認的邏輯轉成 Android 可執行的規格。
- 明確排除錯誤方向，例如把此工作理解為 Kotlin Multiplatform 或 Kotlin/Native。

閱讀本文件時，應將第 1～4 章視為「不可隨意更改的行為契約」，第 5 章視為 Android 專案藍圖。

## 1. 核心業務邏輯 (Core Business Logic)

### 1.1 App 定位

- App 是離線優先的台語辭典。
- 原始資料來源仍是教育部 `kautian.ods`，但 Android app runtime 不直接解析 ODS。
- Android 版的主要查詢來源是本機 SQLite。
- App 支援詞目音檔與例句音檔的離線下載與播放。
- App 支援繁中、簡中、英文介面。
- Android native 指的是一般 Android app：Kotlin + Jetpack Compose + AndroidX，不是 Kotlin/Native，也不是 Kotlin Multiplatform。

### 1.2 啟動初始化流程

- 啟動時需初始化：
  - `AppPreferencesStore`
  - `LocaleManager`
  - `ChineseConversionService`
  - `OfflineAudioStore`
  - `BookmarkStore`
  - `OfflineDictionaryResourceStore`
  - `InitializationViewModel`
- 初始化是阻塞式。
- 若本機 SQLite 未就緒，App 必須停留在初始化畫面，不能進入主功能。
- 初始化流程需處理：
  - 檢查預轉換資料包是否存在
  - 必要時恢復內建預轉換資料包
  - 必要時下載遠端預轉換資料包
  - 判斷 SQLite 是否存在與是否需要 rebuild
  - 由預轉換資料重建 SQLite
  - 寫入 `is_db_ready`

### 1.3 Dictionary Source / Database

- 上游檔名仍為 `kautian.ods`。
- Android app runtime 不直接解析 `kautian.ods`。
- ODS 讀取的選型結論是：沿用既有 `tool/build_dictionary_asset.py` 作為第一版唯一 source-of-truth 轉換器，不在 Android 端新增第二套 ODS parser。
- 建議主要中介格式：`dictionary_entries.jsonl` + `dictionary_manifest.json`。
- DB 檔名：`dictionary.sqlite`。
- 現有 Flutter ODS URL：
  - `https://app.taigidict.org/assets/kautian.ods`
- Android 版應優先下載預轉換資料包，例如：
  - `https://app.taigidict.org/assets/dictionary-json-v1.zip`
  - 或由後續流程下載預建 `dictionary.sqlite`
- 第一版應內建一份預轉換資料包或內建可恢復的 raw source。
- 若下載檔案缺失、大小為 0、checksum 不符或 manifest 不完整，必須視為 invalid 並刪除。
- DB rebuild 判定條件：
  - DB 不存在
  - DB schema 不完整
  - 預轉換資料包版本或 modified time 比 DB 新

第一版的實際資料來源策略：

- build / CI 先以 `tool/build_dictionary_asset.py` 由 `kautian.ods` 產生 JSONL package。
- Android app 只安裝、恢復、下載、驗證 `dictionary_manifest.json` 與 `dictionary_entries.jsonl`。
- `kautian.ods` 可保留為上游資料來源與轉換輸入，但不再作為 Android app runtime rebuild 輸入。
- 若未來需要直接分發預建 `dictionary.sqlite`，仍應由同一條 Python 轉換管線產生，避免雙重規則來源。
- 目前已將這份平台中立的已生成資料包複製到 `android-native/Generated/Dictionary`，Android 第一版可以直接使用。
- 這份資料包本質上仍來自同一條 Python 轉換管線；若後續要降低平台命名耦合，較佳做法是再把生成輸出移到 shared generated directory 或 CI artifact。

### 1.4 預轉換資料規格

- ODS 解析必須發生在 Python 工具、CI pipeline 或後台轉換程序中，不應放在 Android app runtime。
- 目前 repo 內已存在可用的轉換入口：`tool/build_dictionary_asset.py`。
- 第一版 Android native 應直接承接這份轉換器的輸出格式，而不是改寫成 Kotlin 版 ODS 解析器。
- 預轉換器必須讀取必要 sheet：
  - `詞目`
  - `義項`
  - `例句`
- 預轉換器必須支援可選 sheet：
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
  - 內含 `senses` 與 `examples`，避免 Android runtime 再做多表 join 才能匯入。
  - Android rebuild SQLite 時逐行 streaming decode，降低記憶體峰值。

### 1.5 Dictionary 資料模型

#### `DictionaryBundle`

- `entryCount: Int`
- `senseCount: Int`
- `exampleCount: Int`
- `entries: List<DictionaryEntry>`
- `databasePath: String?`
- `isDatabaseBacked: Boolean`

#### `DictionaryEntry`

- `id: Long`
- `type: String`
- `hanji: String`
- `romanization: String`
- `category: String`
- `audioId: String`
- `hokkienSearch: String`
- `mandarinSearch: String`
- `variantChars: List<String>`
- `wordSynonyms: List<String>`
- `wordAntonyms: List<String>`
- `alternativePronunciations: List<String>`
- `contractedPronunciations: List<String>`
- `colloquialPronunciations: List<String>`
- `phoneticDifferences: List<String>`
- `vocabularyComparisons: List<String>`
- `aliasTargetEntryId: Long?`
- `senses: List<DictionarySense>`

衍生規則：

- `redirectsToPrimaryEntry = aliasTargetEntryId != null`
- `briefSummary` 取值順序：
  - 第一個非空 `sense.definition`
  - `category`
  - `type`
  - `romanization`
  - alias entry 的 summary 直接為空

#### `DictionarySense`

- `partOfSpeech: String`
- `definition: String`
- `definitionSynonyms: List<String>`
- `definitionAntonyms: List<String>`
- `examples: List<DictionaryExample>`

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
- 搜尋 query 必須先 normalization：
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
- 第一版不可擅自改成 FTS-only search，也不可改排序權重。

### 1.8 搜尋歷史

- 儲存在偏好設定：`recent_search_history`
- 上限 10 筆
- 僅在查詢有結果時保存
- 新查詢置頂
- 重複查詢會去重後置頂

### 1.9 書籤

- 儲存在偏好設定：`bookmarked_entry_ids`
- 只存 `entryId`
- toggle 行為：
  - 已存在則移除
  - 不存在則插到最前面
- 畫面展示前會重新查表並維持使用者排序

### 1.10 Alias / Linked Entry 規則

- 若 entry 有 `aliasTargetEntryId`，detail 頁必須 resolve 到主詞目後再顯示。
- linked entry lookup 順序需保持：
  - exact hanji
  - variant / related word
  - romanization
- linked entry 不可導回目前已 resolve 的同一詞目。
- alias 行為不能只在 UI 層做字串替換，必須在資料查詢與 detail prepare 階段處理。

### 1.11 簡繁轉換

- 簡繁轉換不是單純 UI 翻譯，而是搜尋流程的一部分。
- `zh-CN` 查詢時，需先把簡體 query 轉成台灣繁體語意後再搜尋。
- `zh-CN` 顯示時，再把台灣繁體詞典內容轉成簡體顯示。
- OpenCC 選型固定使用 `https://github.com/xyrlsz/android-opencc`。
- 必須保留既有語意，並對應到 `android-opencc` 的 conversion config：
  - 搜尋輸入使用 `S2TWP`
  - 顯示輸出使用 `TW2SP`
- 必須保留 `OpenCCInputGuard` 類型的保護：
  - 沒有漢字時不做轉換
  - 字串為空時不做轉換
  - 含不完整 surrogate 或非法 Unicode 時直接回傳原字串
- Android 端不可直接沿用已知有 JNI crash 風險的舊 Flutter plugin 邏輯。
- `android-opencc` 本身是 JNI-backed OpenCC 封裝，因此必須：
  - 在 app 層先做輸入 guard
  - 轉換呼叫需序列化或以可控 dispatcher 執行
  - 發生例外時回傳原字串，不得讓搜尋或 detail rendering crash
  - app 啟動早期呼叫 `ChineseConverter.init(context)`，避免首次轉換時把 JNI 與字典資產初始化成本灌進搜尋互動
  - 若升級 library 版本或更新其內建字典，需在下一次啟動前後安排一次 `ChineseConverter.clearDictDataFolder()`，避免沿用舊的已解包字典檔
- 依該專案 README，目前依賴條件包含：
  - JitPack 來源
  - `com.github.xyrlsz:android-opencc:1.3.8`
  - API 21+
- 不可用 ICU transliterator 或一般簡繁 mapping 取代 OpenCC 語意。

### 1.12 音訊下載與播放

- 音訊 archive 分為兩類：
  - 詞目音檔 `sutiau-mp3.zip`
  - 例句音檔 `leku-mp3.zip`
- 兩者必須分開管理下載狀態與修復流程。
- 下載應支援 pause / resume。
- archive 完成後需能驗證 sample clip 是否可讀。
- 預設策略應是「只抽單一 mp3 到 cache 播放」，不是整包解壓。
- 詞目與例句播放 UI 狀態需能標示 loading / playing / idle。

### 1.13 設定與靜態內容

- Settings 必須支援：
  - 字體大小
  - 介面語言
  - 主題模式
  - 詞典資料維護
  - 詞目音檔維護
  - 例句音檔維護
  - 關於 / 授權 / 隱私 / 參考資料
- 長文參考內容需保留語意、段落、清單與表格可讀性。
- 使用者偏好、書籤、搜尋歷史，不可和 dictionary SQLite 或 archive metadata 混存。

### 1.14 字型與 Font Fallback

- 需要支援 font fallback，因為辭典內容同時包含：
  - 漢字
  - Tailo / POJ 羅馬字
  - 組合附標與特殊字元，例如 `o͘`、`ⁿ`
- Flutter 版目前的既有做法是保留系統字型為主，並額外加入 `TauhuOo` 作為 fallback 字型來源。
- Android native 第一版應維持相同方向：
  - UI 與長文內容預設使用系統字型
  - `TauhuOo20.05-Regular.otf` 作為補字 fallback 資產
  - 不可把 `TauhuOo` 直接當成全 app 的 primary font
- Android 平台層可以支援 font fallback，但 Compose 本身沒有一個足夠高階、可直接表達「system first + app bundled fallback second」的單一步驟 API，因此這是明確的技術選型項。
- 第一版建議策略：
  - 把 `TauhuOo` 納入 Android app font 資產
  - 優先研究 `Typeface.CustomFallbackBuilder` 或等價平台字型鏈結方式
  - 若 Compose 純 typography 設定無法穩定表達 fallback 鏈，則在 dictionary 文字 rendering 層建立專用 text resolver / text style adapter
- font fallback 的目標是補字，不是改變整體視覺語氣；漢字與一般 UI 仍應看起來像原生 Android app。
- 必須驗證：
  - 常見漢字維持系統字型可讀性
  - Tailo / POJ 特殊字元不出現 tofu
  - 混合漢字與羅馬字的同一行文字不因 fallback 導致截斷、selection 或行高異常
  - 大字級與深色模式下 rendering 仍正常

## 2. 狀態管理機制 (State Management Analysis)

### 2.1 Android 目前建議的狀態管理方式

- App 級狀態以 `ViewModel + StateFlow` 為主。
- Compose 畫面只觀察 immutable UI state。
- 長生命週期服務應放在 repository / store 層，不放在 composable。
- 第一版不必先導入複雜 DI 框架；可先用 `AppContainer` 或 `CompositionLocal` 明確組裝依賴。

### 2.2 全域 / 應用級狀態

- `AppSettingsStore`
  - 主題
  - 字體大小
  - 動態色彩開關（若之後採用）
- `LocaleManager`
  - 介面語言 override
  - resolved locale
- `BookmarkStore`
  - bookmark ids
- `OfflineDictionaryResourceStore`
  - dictionary source / rebuild 狀態
- `OfflineAudioStore`
  - 兩份 archive 的下載與播放狀態

### 2.3 啟動與初始化狀態

- 需有明確 phase enum，例如：
  - `Idle`
  - `CheckingResources`
  - `RestoringBundledSource`
  - `DownloadingSource`
  - `RebuildingDatabase`
  - `Ready`
  - `Error`
- 初始化畫面需能顯示：
  - phase label
  - progress percent 或 processed/total
  - retry action
- 初始化成功後應有資料庫 generation 概念，供搜尋頁在 rebuild 後重新載入。

### 2.4 Dictionary 搜尋狀態

- `searchText`
- `normalizedQuery`
- `isSearching`
- `results`
- `searchHistory`
- `selectedTabletEntryId`
- `selectedTabletDetail`
- `isLoadingTabletDetail`
- debounce 為 300 ms。
- 新 query 必須取消舊 query 的搜尋 job。
- 清空 query 時，結果與 loading 狀態應立即歸零。

### 2.5 頁面局部狀態

- detail 頁播放中的 clip key
- bookmark button optimistic update
- share sheet 觸發狀態
- settings confirmation dialog
- 下載中 tile 的 loading / paused / completed / error 狀態

### 2.6 狀態行為上的隱性需求

- locale 改變後，當前可見畫面應重新顯示可翻譯內容，但不應無條件重建整個資料庫。
- rebuild 成功後，search cache 與 detail cache 必須失效。
- bookmark 改變後，detail 頁與 bookmarks 頁必須同步更新。
- 音訊播放切換到另一 clip 時，前一個 clip 應停止。

## 3. UI 畫面清單與互動 (UI Screens & Interactions)

### 3.1 App Initialization Screen

- 顯示 app 名稱、初始化狀態與進度。
- 若需要恢復資源或重建資料庫，必須在此畫面完成。
- 初始化失敗時顯示錯誤訊息與 retry。

### 3.2 Main Shell

- 主功能分三區：
  - Dictionary
  - Bookmarks
  - Settings
- Phone 上以 bottom navigation 為主。
- 大螢幕裝置可切換為 navigation rail 或 adaptive navigation suite。
- 不要建立額外第四個頂層分頁來放 About 或 License。

### 3.3 Dictionary Screen

- 進入點是搜尋框。
- 空 query 顯示 recent search history。
- 非空 query 顯示搜尋結果列表。
- 搜尋結果 cell 需呈現：
  - hanji
  - romanization
  - brief summary
  - bookmark state 或可後續延伸的 affordance
- 點擊結果後：
  - phone 進 detail route
  - tablet 顯示 list-detail 佈局

### 3.4 Word Detail Screen

- 若 entry 是 alias，需先 resolve 再 render。
- 畫面需顯示：
  - 詞頭資訊
  - 詞性與解釋
  - 例句
  - 近義 / 反義 / 異用字 / 其他關聯詞
  - 詞目音檔與例句音檔播放
- 定義中的可點詞彙需能開啟對應詞目。
- share 文案格式需與現有產品一致。

### 3.5 Bookmarks Screen

- 以 bookmark ids 重新查詢完整 entry 後呈現。
- 無資料時需有 empty state。
- 大螢幕可改用 grid，但不可犧牲資訊可讀性。

### 3.6 Settings Screen

- 顯示語言、主題、字體大小。
- 顯示 dictionary resource 狀態。
- 顯示兩個 audio archive 狀態。
- 需要能進入 advanced maintenance。

### 3.7 Advanced Settings Screen

- 手動重新下載 dictionary source
- 手動 rebuild SQLite
- 手動修復詞目音檔 archive
- 手動修復例句音檔 archive
- 危險動作前需有 confirmation

### 3.8 About / License / Reference Screens

- 保留 privacy policy、license summary、license overview、Tailo/Hanji 參考文章。
- 長文需優先考慮可讀性與字級縮放。
- 不要把這些長文直接塞進一個超長 settings 頁。

## 4. Android Native 遷移策略建議 (Migration Strategy to Android Native)

### 4.1 基本原則

- 第一階段目標是功能 parity，不是架構炫技。
- 優先保留：
  - SQLite schema
  - 搜尋 normalization
  - 搜尋排序
  - alias resolve
  - OpenCC 語意
  - 音訊 zip index 策略
- 先保留資料與流程語意，再考慮第二階段優化。

### 4.2 資料庫建議

- 建議使用 `Room` 作為 Android 的資料庫入口。
- 原因：
  - 仍可直接維持現有 SQLite schema
  - migration 管理清楚
  - 容易整合 coroutine 與 test setup
  - 可在搜尋路徑使用 `@RawQuery` 或 `SupportSQLiteQuery` 保留既有 SQL 排序
- 第一版不建議：
  - 直接改用網路 API 作主資料來源
  - 直接把搜尋重寫成 FTS ranking
  - 把資料模型塞成單表 document store

### 4.3 詞典資料重建策略

- Android runtime 不應直接解析 ODS。
- 第一版建議採 JSONL rebuild：
  - App 內建或下載 `dictionary-json-v1.zip`
  - zip 內含 `dictionary_manifest.json` 與 `dictionary_entries.jsonl`
  - App streaming decode JSONL 並寫入 SQLite
- 若後續 CI 已可穩定輸出預建 `dictionary.sqlite`，可於第二階段評估直接替換 DB。

### 4.4 狀態管理對應

- `ChangeNotifier` -> `ViewModel + StateFlow`
- `InheritedNotifier scope` -> `AppContainer` / `CompositionLocal` / 明確參數注入
- `FutureBuilder` -> `collectAsStateWithLifecycle` + phase state
- `setState` 局部狀態 -> `rememberSaveable` 或畫面專屬 state holder

### 4.5 持久化對應

- `SharedPreferences` -> `Preferences DataStore`
- 建議集中 key 定義，例如：
  - `interface_locale`
  - `theme_preference`
  - `reading_text_scale`
  - `recent_search_history`
  - `bookmarked_entry_ids`
  - `is_db_ready`
- 若資料量仍小，bookmarks 與 search history 可先維持 DataStore 存陣列字串；不要為了這兩份小資料擴張 schema。

### 4.6 中文轉換建議

- 必須隔離在 `ChineseConversionService` 後。
- 這層 service 需要提供：
  - `normalizeSearchInput(text, locale)`
  - `translateForDisplay(text, locale)`
- Android 實作固定使用 `android-opencc`。
- 搜尋輸入維持 `S2TWP` 語意。
- 簡中顯示維持 `TW2SP` 語意。
- 不可把 conversion 直接散落在 composable 或 DAO 中。
- 依賴應 pin 在明確版本，第一版文件以 `1.3.8` 為基準。
- 因該 library 會在第一次轉換時把字典資產複製到 app data directory，初始化策略必須納入 cold start 與 upgrade 行為。
- 需明確記錄 crash guard、執行緒策略與字典清理策略。

### 4.7 音訊與下載建議

- 下載層建議使用 `OkHttp` 或等價可控 HTTP client。
- 必須保留 `Range` header 續傳能力。
- 播放層建議使用 `Media3`。
- zip index 可用 `java.util.zip.ZipFile` 或等價可隨機讀取方案。
- 第一版預設以 app 內 foreground 下載為主；若要支援長時間背景下載，再額外評估 `WorkManager`。

### 4.8 UI 元件對應

| Flutter 元件 | Android Compose 對應 |
| --- | --- |
| `AdaptiveScaffold` | `NavigationSuiteScaffold` 或 `Scaffold + NavigationBar/Rail` |
| 搜尋框 | `SearchBar` 或自訂 `TextField` |
| `Card` | `ElevatedCard` / `OutlinedCard` |
| `AdaptiveListTile` | `ListItem` / clickable row |
| `LinearProgressIndicator` | `LinearProgressIndicator` |
| `ActionChip` / pill | `AssistChip` / `FilterChip` |
| `FutureBuilder` | `collectAsStateWithLifecycle` + UiState |
| share sheet | Android Sharesheet intent |

補充：Typography 不應一開始就全域改成自訂字型。對 dictionary 內容的 Tailo fallback 需求，應由專門的文字策略處理，而不是讓整個 Material typography 脫離系統字型。

### 4.9 建議的 Tablet 佈局

- Dictionary：list-detail 兩欄布局
- Bookmarks：adaptive grid
- Settings：單欄表單即可，必要時於大螢幕增加說明欄

### 4.10 不可丟失的行為

- 搜尋 300 ms debounce
- 清空 query 時立即清空結果
- 只在有結果時保存 history
- romanization normalization 規則完整保留
- alias resolve 保留
- linked entry 排除導回自己
- 簡體 query 先轉繁搜尋
- rebuild 成功後 cache invalidation
- 音訊下載可 pause/resume

## 5. Android 原生專案藍圖 (Next Step Blueprint)

### 5.1 建議檔案樹

```text
android-native/
  settings.gradle.kts
  build.gradle.kts
  gradle.properties
  app/
    build.gradle.kts
    src/main/
      AndroidManifest.xml
      kotlin/org/taigidict/app/
        MainActivity.kt
        app/
          TaigiDictApplication.kt
          AppContainer.kt
          MainAppState.kt
        core/
          constants/
            AppConstants.kt
            PreferenceKeys.kt
          localization/
            AppLocale.kt
            LocaleManager.kt
          preferences/
            AppPreferencesStore.kt
          util/
            QueryNormalizer.kt
            TextNormalization.kt
            ByteFormatter.kt
        data/
          database/
            TaigiDictDatabase.kt
            DictionaryEntryEntity.kt
            DictionarySenseEntity.kt
            DictionaryExampleEntity.kt
            DictionaryMetadataEntity.kt
            DictionaryDao.kt
            DictionaryMigrations.kt
          import/
            DictionaryImportService.kt
            DictionaryJsonlReader.kt
            DictionaryManifest.kt
          repository/
            DictionaryRepository.kt
            BookmarkRepository.kt
            PreferencesRepository.kt
          audio/
            AudioArchiveStore.kt
            AudioZipIndexService.kt
            AudioPlaybackService.kt
          conversion/
            ChineseConversionService.kt
            OpenCcInputGuard.kt
        domain/
          model/
            DictionaryBundle.kt
            DictionaryEntry.kt
            DictionarySense.kt
            DictionaryExample.kt
            PreparedWordDetail.kt
            DownloadSnapshot.kt
          service/
            DictionarySearchService.kt
            LinkedEntryResolver.kt
            ShareTextBuilder.kt
        feature/
          initialization/
            InitializationViewModel.kt
            InitializationScreen.kt
          dictionary/
            DictionarySearchViewModel.kt
            DictionaryScreen.kt
            DictionaryListPane.kt
            SearchHistorySection.kt
            EntryRow.kt
          worddetail/
            WordDetailViewModel.kt
            WordDetailScreen.kt
            SenseSection.kt
            ExampleCard.kt
            RelationshipChipRow.kt
          bookmarks/
            BookmarksViewModel.kt
            BookmarksScreen.kt
          settings/
            SettingsViewModel.kt
            SettingsScreen.kt
            AdvancedSettingsScreen.kt
          info/
            AboutScreen.kt
            LicenseSummaryScreen.kt
            LicenseOverviewScreen.kt
            ReferenceArticleScreen.kt
        navigation/
          MainDestination.kt
          MainNavGraph.kt
        ui/theme/
          Color.kt
          Theme.kt
          Type.kt
      res/
        values/
        values-zh-rTW/
        values-zh-rCN/
        values-en/
```

### 5.2 建議的 ViewModel 邊界

#### `InitializationViewModel`

- `phase`
- `progress`
- `processedUnits`
- `totalUnits`
- `errorMessage`
- `isReady`
- `databaseGeneration`

#### `DictionarySearchViewModel`

- `searchText`
- `normalizedQuery`
- `isSearching`
- `results`
- `searchHistory`
- `selectedTabletEntryId`
- `selectedTabletDetail`
- `isLoadingTabletDetail`

#### `WordDetailViewModel`

- `entry`
- `resolvedEntryId`
- `openableWords`
- `isBookmarked`
- `loadingClipKey`
- `playingClipKey`
- `errorMessage`

#### `BookmarksViewModel`

- `entries`
- `isLoading`
- `isEmpty`

#### `SettingsViewModel`

- `selectedLocale`
- `themePreference`
- `textScale`
- `dictionarySnapshot`
- `wordAudioSnapshot`
- `sentenceAudioSnapshot`

### 5.3 建議的 Search Service 介面

```kotlin
interface DictionarySearchService {
    fun normalizeQuery(input: String): String
    suspend fun search(query: String, limit: Int, offset: Int): List<DictionaryEntry>
    suspend fun findLinkedEntry(word: String): DictionaryEntry?
    suspend fun entries(ids: List<Long>): List<DictionaryEntry>
    suspend fun entry(id: Long): DictionaryEntry?
}
```

### 5.4 建議的重構階段

#### Phase 1

- 建立 Android app shell
- 建立 SQLite/Room 讀取
- 完成 dictionary search
- 完成 detail / bookmark / settings 基本頁面

#### Phase 2

- 完成 OpenCC-backed 查詢與顯示轉換
- 完成平板 list-detail layout
- 完成搜尋歷史與書籤持久化

#### Phase 3

- 完成 JSONL 詞典資料包 rebuild
- 完成 archive 下載 / pause / resume
- 完成 zip 單檔抽取播放

#### Phase 4

- 完成 reference / license / privacy screens
- 視覺與互動 polish
- 測試與效能收斂

### 5.5 後續 AI Agent 的執行約束

- 不可把 Android native 理解成 Kotlin/Native 或 KMP。
- 不可改變搜尋 normalization 規則。
- 不可改變搜尋排序規則。
- 不可刪除 alias resolve。
- 不可把簡體轉換直接改成 UI 層字串替換。
- 不可把音訊 archive 改成整包解壓為預設行為。
- 第一版不可用 network-only dictionary 取代本機 SQLite。
