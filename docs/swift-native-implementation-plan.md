# Taigi Dict Swift Native Implementation Plan

本文是 `ios-native-migration-spec.md` 的執行版補充。  
前者描述 Flutter 既有行為與遷移策略；本文描述 Swift / SwiftUI 重寫時的檔案邊界、資料庫對照、型別骨架與 agent 任務拆分。

## 實作狀態註記（2026-05-01）

本計畫中的大部分核心項目已在 `ios-native/` 完成，後續閱讀時請將其視為「設計與對照文件」，而非純待辦清單。

- 已實作：GRDB/SQLite 資料層、JSONL 匯入、OpenCC 轉換、搜尋服務、Dictionary / Bookmarks / Settings / Initialization / Info UI、離線音訊下載與播放。
- 已實作但不在 `ios-native/Sources/` 內：ODS 轉換工具位於 `tool/build_dictionary_asset.py`。
- 已實作且已由 Native app 裝配：bundled dictionary directory 與 `DictionarySourceResourceStore` 注入位於 `ios-native/NativeApp/TaigiDictNativeApp.swift`。
- 目前最主要的未完成項：第 9 章 Testing Matrix 中的 integration tests 與 UI snapshot targets；現況以單元測試為主。

因此，第 8 章 Agent Task Breakdown 與第 10 章 Initial Build Order 應視為歷史執行計畫，不再代表當前尚未完成的工作量。

## 1. Implementation Principles

- 第一版以行為等價為目標。
- 資料庫 schema 先保持與 Flutter 版一致。
- 搜尋 normalization 與排序不可改寫成近似邏輯。
- OpenCC 流程先保留，並使用 `PhoenixEmik/SwiftyOpenCC`：簡體 query 轉台灣繁體搜尋，顯示時再轉簡體。
- iOS 端以 SwiftUI + Observation + GRDB 作為基礎。
- Swift App 不直接解析 `kautian.ods`。
- ODS 需在 build time、CI 或後台預轉換成 JSONL/CSV，Swift 端只讀預轉換資料包或預建 SQLite。
- 詞典資料包 rebuild 可分階段完成，但 SQLite 讀取與查詢 API 需先按最終 schema 設計。

### 1.1 Conversion Pipeline

Recommended pipeline:

```text
kautian.ods
  -> conversion tool
  -> dictionary_manifest.json
  -> dictionary_entries.jsonl
  -> dictionary-json-v1.zip
  -> bundled asset or remote download
  -> Swift DictionaryImportService
  -> dictionary.sqlite
```

Conversion tool requirements:

- May be implemented in Dart, Python, or a CI-side command line tool.
- Must reuse the same sheet mapping rules documented in `ios-native-migration-spec.md`.
- Must produce normalized `hokkienSearch` and `mandarinSearch` values before packaging.
- Must fail the build if required sheets are missing or if entry/sense/example counts are inconsistent.
- Must emit a manifest checksum so the Swift app can reject partial or mismatched packages.

### 1.2 SwiftyOpenCC Integration

Chinese conversion must be isolated behind `ChineseConversionService`.

Dependency:

```text
https://github.com/PhoenixEmik/SwiftyOpenCC.git
```

Required implementation notes:

- Import module `OpenCC`.
- Use `ChineseConverter` inside the service or adapter layer only.
- Keep the old Flutter conversion semantics: search input uses equivalent `S2TWp`; simplified Chinese display uses equivalent `TW2Sp`.
- Keep `OpenCCInputGuard` before conversion so romanization-only text and invalid Unicode are returned unchanged.
- Pin the Swift Package to a release tag or commit in Xcode project configuration for reproducible Xcode Cloud builds.

Suggested service boundary:

```swift
import OpenCC

actor ChineseConversionService: ChineseConversionProviding {
    func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String {
        // zh-CN: convert simplified query to Taiwanese Traditional before search.
        // others: return text unchanged after guard.
    }

    func translateForDisplay(_ text: String, locale: AppLocale) async -> String {
        // zh-CN: convert Traditional dictionary text to Simplified for display.
        // others: return text unchanged after guard.
    }
}
```

Acceptance checks:

- Romanization-only input such as `su-tian` is unchanged.
- Malformed Unicode is unchanged and does not crash.
- Simplified Chinese search terms normalize to Traditional/Taiwanese forms before repository lookup.
- `zh-CN` UI displays converted Simplified text without changing stored database rows.

## 2. Proposed Package Layout

```text
TaigiDict/
  TaigiDictApp.swift

  App/
    AppEnvironment.swift
    AppRootView.swift
    MainTabView.swift

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
      ByteFormatter.swift
      TextNormalization.swift

  Domain/
    Dictionary/
      DictionaryBundle.swift
      DictionaryEntry.swift
      DictionarySense.swift
      DictionaryExample.swift
      PreparedWordDetail.swift
    Audio/
      AudioArchiveType.swift
      DownloadSnapshot.swift
      AudioActionResult.swift

  Data/
    Database/
      DatabaseManager.swift
      DictionaryMigrations.swift
      DictionaryEntryRecord.swift
      DictionarySenseRecord.swift
      DictionaryExampleRecord.swift
      DictionaryMetadataRecord.swift
    Dictionary/
      DictionaryRepository.swift
      DictionarySearchService.swift
      DictionaryImportService.swift
      DictionaryJSONLReader.swift
      DictionaryManifest.swift
    Audio/
      ResumableDownloadService.swift
      AudioArchiveStorage.swift
      AudioZipIndexService.swift
      AudioPlaybackService.swift
      OfflineAudioStore.swift
    Conversion/
      ChineseConversionService.swift
      OpenCCInputGuard.swift
    Bookmarks/
      BookmarkStore.swift

  Features/
    Initialization/
      InitializationPhase.swift
      InitializationViewModel.swift
      InitializationView.swift
    Dictionary/
      DictionarySearchViewModel.swift
      DictionaryScreen.swift
      DictionarySplitView.swift
      SearchFieldView.swift
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
      BookmarksViewModel.swift
      BookmarksScreen.swift
    Settings/
      SettingsScreen.swift
      AdvancedSettingsScreen.swift
      ResourceTileView.swift
      AboutScreen.swift
      LicenseSummaryScreen.swift
      LicenseOverviewScreen.swift
      ReferenceArticleScreen.swift
```

## 3. SQLite Schema Mapping

### 3.1 `dictionary_entries`

| SQLite column | Swift property | Type | Notes |
|---|---|---|---|
| `id` | `id` | `Int64` | Primary key |
| `type` | `type` | `String` | 詞目類型 |
| `hanji` | `hanji` | `String` | 漢字詞頭 |
| `romanization` | `romanization` | `String` | 羅馬字 |
| `category` | `category` | `String` | 分類 |
| `audio_id` | `audioID` | `String` | 詞目音檔 id |
| `variant_chars` | `variantCharsJSON` | `String` | JSON array |
| `word_synonyms` | `wordSynonymsJSON` | `String` | JSON array |
| `word_antonyms` | `wordAntonymsJSON` | `String` | JSON array |
| `alternative_pronunciations` | `alternativePronunciationsJSON` | `String` | JSON array |
| `contracted_pronunciations` | `contractedPronunciationsJSON` | `String` | JSON array |
| `colloquial_pronunciations` | `colloquialPronunciationsJSON` | `String` | JSON array |
| `phonetic_differences` | `phoneticDifferencesJSON` | `String` | JSON array |
| `vocabulary_comparisons` | `vocabularyComparisonsJSON` | `String` | JSON array |
| `alias_target_entry_id` | `aliasTargetEntryID` | `Int64?` | Alias target |
| `hokkien_search` | `hokkienSearch` | `String` | Normalized search index |
| `mandarin_search` | `mandarinSearch` | `String` | Normalized search index |

### 3.2 `dictionary_senses`

| SQLite column | Swift property | Type | Notes |
|---|---|---|---|
| `entry_id` | `entryID` | `Int64` | Composite primary key |
| `sense_id` | `senseID` | `Int64` | Composite primary key |
| `part_of_speech` | `partOfSpeech` | `String` | 詞性 |
| `definition` | `definition` | `String` | 解說 |
| `definition_synonyms` | `definitionSynonymsJSON` | `String` | JSON array |
| `definition_antonyms` | `definitionAntonymsJSON` | `String` | JSON array |

### 3.3 `dictionary_examples`

| SQLite column | Swift property | Type | Notes |
|---|---|---|---|
| `id` | `id` | `Int64?` | Auto increment |
| `entry_id` | `entryID` | `Int64` | Entry FK by convention |
| `sense_id` | `senseID` | `Int64` | Sense id |
| `example_order` | `exampleOrder` | `Int` | Sorting |
| `hanji` | `hanji` | `String` | 例句漢字 |
| `romanization` | `romanization` | `String` | 例句羅馬字 |
| `mandarin` | `mandarin` | `String` | 華語 |
| `audio_id` | `audioID` | `String` | 例句音檔 id |

### 3.4 `dictionary_metadata`

| SQLite key | Meaning |
|---|---|
| `built_at` | DB build time in UTC ISO8601 |
| `source_modified_at` | Upstream ODS or converted package modified time in UTC ISO8601 |
| `entry_count` | Entry count |
| `sense_count` | Sense count |
| `example_count` | Example count |

## 4. Swift Domain Type Skeletons

```swift
struct DictionaryBundle: Sendable {
    var entryCount: Int
    var senseCount: Int
    var exampleCount: Int
    var entries: [DictionaryEntry]
    var databasePath: String?

    var isDatabaseBacked: Bool {
        databasePath != nil
    }
}

struct DictionaryEntry: Identifiable, Hashable, Sendable {
    var id: Int64
    var type: String
    var hanji: String
    var romanization: String
    var category: String
    var audioID: String
    var hokkienSearch: String
    var mandarinSearch: String
    var variantChars: [String]
    var wordSynonyms: [String]
    var wordAntonyms: [String]
    var alternativePronunciations: [String]
    var contractedPronunciations: [String]
    var colloquialPronunciations: [String]
    var phoneticDifferences: [String]
    var vocabularyComparisons: [String]
    var aliasTargetEntryID: Int64?
    var senses: [DictionarySense]

    var redirectsToPrimaryEntry: Bool {
        aliasTargetEntryID != nil
    }

    var briefSummary: String {
        if redirectsToPrimaryEntry { return "" }
        if let definition = senses.first(where: { !$0.definition.isEmpty })?.definition {
            return definition
        }
        if !category.isEmpty { return category }
        if !type.isEmpty { return type }
        return romanization
    }
}

struct DictionarySense: Hashable, Sendable {
    var partOfSpeech: String
    var definition: String
    var definitionSynonyms: [String]
    var definitionAntonyms: [String]
    var examples: [DictionaryExample]
}

struct DictionaryExample: Hashable, Sendable {
    var hanji: String
    var romanization: String
    var mandarin: String
    var audioID: String
}

struct PreparedWordDetail: Sendable {
    var entry: DictionaryEntry
    var resolvedEntryID: Int64
    var openableWords: Set<String>

    func canOpenWord(_ word: String) -> Bool {
        openableWords.contains(word)
    }
}
```

## 5. GRDB Record Skeletons

```swift
import Foundation
import GRDB

struct DictionaryEntryRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "dictionary_entries"

    var id: Int64
    var type: String
    var hanji: String
    var romanization: String
    var category: String
    var audioID: String
    var variantCharsJSON: String
    var wordSynonymsJSON: String
    var wordAntonymsJSON: String
    var alternativePronunciationsJSON: String
    var contractedPronunciationsJSON: String
    var colloquialPronunciationsJSON: String
    var phoneticDifferencesJSON: String
    var vocabularyComparisonsJSON: String
    var aliasTargetEntryID: Int64?
    var hokkienSearch: String
    var mandarinSearch: String

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let hanji = Column(CodingKeys.hanji)
        static let hokkienSearch = Column(CodingKeys.hokkienSearch)
        static let mandarinSearch = Column(CodingKeys.mandarinSearch)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case hanji
        case romanization
        case category
        case audioID = "audio_id"
        case variantCharsJSON = "variant_chars"
        case wordSynonymsJSON = "word_synonyms"
        case wordAntonymsJSON = "word_antonyms"
        case alternativePronunciationsJSON = "alternative_pronunciations"
        case contractedPronunciationsJSON = "contracted_pronunciations"
        case colloquialPronunciationsJSON = "colloquial_pronunciations"
        case phoneticDifferencesJSON = "phonetic_differences"
        case vocabularyComparisonsJSON = "vocabulary_comparisons"
        case aliasTargetEntryID = "alias_target_entry_id"
        case hokkienSearch = "hokkien_search"
        case mandarinSearch = "mandarin_search"
    }
}

struct DictionarySenseRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "dictionary_senses"

    var entryID: Int64
    var senseID: Int64
    var partOfSpeech: String
    var definition: String
    var definitionSynonymsJSON: String
    var definitionAntonymsJSON: String

    enum CodingKeys: String, CodingKey {
        case entryID = "entry_id"
        case senseID = "sense_id"
        case partOfSpeech = "part_of_speech"
        case definition
        case definitionSynonymsJSON = "definition_synonyms"
        case definitionAntonymsJSON = "definition_antonyms"
    }
}

struct DictionaryExampleRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "dictionary_examples"

    var id: Int64?
    var entryID: Int64
    var senseID: Int64
    var exampleOrder: Int
    var hanji: String
    var romanization: String
    var mandarin: String
    var audioID: String

    enum CodingKeys: String, CodingKey {
        case id
        case entryID = "entry_id"
        case senseID = "sense_id"
        case exampleOrder = "example_order"
        case hanji
        case romanization
        case mandarin
        case audioID = "audio_id"
    }
}
```

## 6. Repository Contract

```swift
protocol DictionaryRepositoryProtocol: Sendable {
    func loadBundle() async throws -> DictionaryBundle
    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry]
    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry?
    func entries(ids: [Int64]) async throws -> [DictionaryEntry]
    func entry(id: Int64) async throws -> DictionaryEntry?
    func clearBundleCache()
}
```

### Required SQL Search Query

```sql
SELECT id
FROM dictionary_entries
WHERE hanji LIKE ? ESCAPE '\'
   OR hokkien_search LIKE ? ESCAPE '\'
   OR mandarin_search LIKE ? ESCAPE '\'
   OR EXISTS (
     SELECT 1
     FROM dictionary_senses
     WHERE dictionary_senses.entry_id = dictionary_entries.id
       AND dictionary_senses.definition LIKE ? ESCAPE '\'
   )
   OR EXISTS (
     SELECT 1
     FROM dictionary_examples
     WHERE dictionary_examples.entry_id = dictionary_entries.id
       AND (
         dictionary_examples.hanji LIKE ? ESCAPE '\'
         OR dictionary_examples.mandarin LIKE ? ESCAPE '\'
       )
   )
ORDER BY
  CASE
    WHEN hanji = ? THEN 0
    WHEN hokkien_search LIKE ? ESCAPE '\' THEN 1
    WHEN hanji LIKE ? ESCAPE '\' THEN 1
    ELSE 2
  END ASC,
  length(hokkien_search) ASC,
  id ASC
LIMIT ? OFFSET ?
```

## 7. ViewModel Contracts

### `DictionarySearchViewModel`

```swift
@MainActor
@Observable
final class DictionarySearchViewModel {
    var searchText = ""
    var normalizedQuery = ""
    var isSearching = false
    var results: [DictionaryEntry] = []
    var searchHistory: [String] = []
    var selectedTabletDetail: PreparedWordDetail?
    var isLoadingTabletDetail = false

    private var searchTask: Task<Void, Never>?

    func load() async {}
    func scheduleSearch() {}
    func submitQuery() async {}
    func applyHistoryQuery(_ query: String) async {}
    func clearSearchHistory() async {}
    func selectEntry(_ entry: DictionaryEntry) async {}
}
```

Acceptance criteria:

- Empty query clears results immediately.
- Non-empty query waits 300 ms before searching.
- A newer query cancels any pending or running older search.
- History saves only when results are non-empty.
- History max count is 10.

### `WordDetailViewModel`

```swift
@MainActor
@Observable
final class WordDetailViewModel {
    var entry: DictionaryEntry?
    var resolvedEntryID: Int64?
    var openableWords: Set<String> = []
    var isPreparing = false
    var errorMessage: String?

    func prepare(entry: DictionaryEntry) async {}
    func toggleBookmark() async {}
    func playWordAudio() async {}
    func playExampleAudio(_ example: DictionaryExample) async {}
    func linkedEntry(for word: String) async -> DictionaryEntry? { nil }
    func shareText() -> String { "" }
}
```

Acceptance criteria:

- Alias entries resolve before display.
- Openable chips exclude links pointing back to current resolved entry.
- Share text matches Flutter format.
- Audio errors surface as user-visible messages.

### `InitializationViewModel`

```swift
@MainActor
@Observable
final class InitializationViewModel {
    var phase: InitializationPhase = .idle
    var progress: Double?
    var processedUnits = 0
    var totalUnits = 0
    var errorMessage: String?
    var databaseGeneration = 0

    var isReady: Bool { phase == .ready }

    func start() async {}
    func retry() async {}
    func rebuild() async {}
}
```

Acceptance criteria:

- App cannot enter main tabs until `isReady == true`.
- Rebuild success increments `databaseGeneration`.
- Corrupted converted dictionary package deletes source and attempts redownload.

## 8. Agent Task Breakdown

### Agent 1: Project Shell

Scope:

- Create SwiftUI app shell.
- Add `TabView` with Dictionary / Bookmarks / Settings.
- Add shared environment stores.

Deliverables:

- `TaigiDictApp.swift`
- `AppEnvironment.swift`
- `MainTabView.swift`
- Basic locale/theme settings stores.

Acceptance criteria:

- App launches to initialization gate.
- Tabs are visible after mocked ready state.

### Agent 2: Database Layer

Scope:

- Add GRDB.
- Implement migrations.
- Implement records and model mapping.
- Implement read-only bundle loading.

Deliverables:

- `DatabaseManager.swift`
- `DictionaryMigrations.swift`
- record structs
- `DictionaryRepository.swift`

Acceptance criteria:

- Can open an existing `dictionary.sqlite`.
- Can load metadata counts.
- Can load entries by ids preserving requested order.

### Agent 3: Search Parity

Scope:

- Port normalization.
- Port SQL search.
- Port linked entry lookup.

Deliverables:

- `TextNormalization.swift`
- `DictionarySearchService.swift`
- unit tests for normalization and ranking.

Acceptance criteria:

- `Tsìt4-tsi̍t8/【狗】` normalizes to `tsit tsit 狗`.
- Exact headword ranks before longer headword and definition matches.
- Linked lookup prefers exact hanji, variant, then romanization.

### Agent 4: Dictionary UI

Scope:

- Search screen.
- Search history.
- Entry rows.
- Phone detail navigation.
- iPad split view.

Deliverables:

- `DictionarySearchViewModel.swift`
- `DictionaryScreen.swift`
- `DictionarySplitView.swift`
- `EntryRowView.swift`

Acceptance criteria:

- 300 ms debounce.
- Clear button clears query and results.
- Phone pushes detail.
- iPad uses split view.

### Agent 5: Word Detail

Scope:

- Detail screen.
- Alias resolve integration.
- Definition links.
- Relationship chips.
- Share text.

Deliverables:

- `WordDetailViewModel.swift`
- `WordDetailScreen.swift`
- `SenseSectionView.swift`
- `RelationshipChipView.swift`

Acceptance criteria:

- Definition `【詞】` renders as tappable text.
- Linked word opens target entry.
- Bookmark button updates immediately.
- Share output matches Flutter format.

### Agent 6: Bookmarks

Scope:

- Bookmark persistence.
- Bookmark list/grid.
- Entry lookup.

Deliverables:

- `BookmarkStore.swift`
- `BookmarksViewModel.swift`
- `BookmarksScreen.swift`

Acceptance criteria:

- Toggle bookmark persists through app restart.
- Empty state appears when no bookmarks.
- iPad uses grid.

### Agent 7: Offline Resources

Scope:

- Dictionary source resource state.
- Resumable downloads.
- Audio archive store.
- Zip index and clip extraction.
- Audio playback.

Deliverables:

- `ResumableDownloadService.swift`
- `AudioArchiveStorage.swift`
- `AudioZipIndexService.swift`
- `AudioPlaybackService.swift`
- `OfflineAudioStore.swift`

Acceptance criteria:

- Download can pause/resume.
- Completed archive validates sample clip id.
- Playing a clip extracts only that mp3 to cache.
- Tapping current clip stops playback.

### Agent 8: Converted Dictionary Rebuild

Scope:

- Implement JSONL or CSV dictionary package reader.
- Validate `dictionary_manifest.json`.
- Streaming decode converted entries.
- Write SQLite in chunks.
- Emit progress.

Deliverables:

- `DictionaryJSONLReader.swift`
- `DictionaryManifest.swift`
- `DictionaryImportService.swift`
- import tests with fixture JSONL package.

Acceptance criteria:

- Missing manifest produces typed error.
- Empty or malformed JSONL produces corrupted source error.
- Manifest counts match imported SQLite counts.
- Rebuild writes metadata and all expected tables.

### Agent 9: Settings and Static Content

Scope:

- Settings form.
- Advanced maintenance.
- About.
- License summary.
- Reference articles.

Deliverables:

- `SettingsScreen.swift`
- `AdvancedSettingsScreen.swift`
- `AboutScreen.swift`
- `LicenseSummaryScreen.swift`
- `ReferenceArticleScreen.swift`

Acceptance criteria:

- Theme, locale, and text scale persist.
- Rebuild confirmation appears before rebuild.
- Reference articles render paragraphs, bullets, and tables.

## 9. Testing Matrix

### Unit Tests

- Query normalization.
- Search ranking.
- Linked entry lookup.
- Alias resolve.
- Share text generation.
- SwiftyOpenCC input guard.
- Bookmark persistence.
- Text scale snapping.
- Download snapshot transitions.
- Zip index parsing.

目前狀態：此區多數已落地，`ios-native/Tests/` 已涵蓋 normalization、bookmark、settings、audio snapshot、dictionary import、initialization 等單元測試。

### Integration Tests

- Open bundled SQLite and run search.
- Open word detail from search result.
- Toggle bookmark and verify bookmark tab.
- Change locale and verify display conversion.
- Simulate failed initialization and retry.

目前狀態：此區仍是主要缺口，尚未看到對應的整合測試 target 或等價測試套件。

### UI Snapshot Targets

- iPhone light/dark dictionary search.
- iPhone word detail.
- iPad split view.
- Settings form.
- Resource download tile states.

目前狀態：尚未實作對應的 snapshot 測試基礎設施或測試目標。

## 10. Initial Build Order

1. Create SwiftUI shell and environment stores.
2. Add GRDB and schema migrations.
3. Port models and repository read APIs.
4. Port normalization and search.
5. Build dictionary search UI.
6. Build word detail UI.
7. Add bookmarks.
8. Add settings.
9. Add SwiftyOpenCC-backed `ChineseConversionService`.
10. Add audio and download services.
11. Add converted dictionary package rebuild.
