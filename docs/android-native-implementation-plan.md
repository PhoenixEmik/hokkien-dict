# Taigi Dict Android Native Implementation Plan

本文是 `android-native-migration-spec.md` 的執行版補充。
前者描述 Flutter 既有行為、iOS native 已確認的產品策略與 Android 遷移邊界；本文描述 Kotlin / Compose 重寫時的檔案邊界、資料庫對照、型別骨架與實作拆分。

## 實作狀態註記（2026-05-02）

目前 `android-native/` 尚未建立實際 app 專案。本計畫因此不是對現狀的盤點，而是 Android native 開工前的落地設計文件。

此文件的目標：

- 讓 Android 實作能直接對齊既有產品邏輯。
- 避免在資料層、搜尋邏輯與離線資源策略上重做決策。
- 把第一版的技術選型固定在可收斂的範圍內。

## 1. Implementation Principles

- 第一版以行為等價為目標。
- 資料庫 schema 先保持與 Flutter / iOS native 一致。
- 搜尋 normalization 與排序不可改寫成近似邏輯。
- Android 端以 Kotlin + Jetpack Compose + ViewModel + Room + DataStore 作為基礎。
- Android app runtime 不直接解析 `kautian.ods`。
- ODS 應在 build time、CI 或後台預轉換成 JSONL/CSV，Android 端只讀預轉換資料包或預建 SQLite。
- 第一版沿用既有 `tool/build_dictionary_asset.py` 作為 ODS 轉換器，不新增 Kotlin ODS parser。
- 第一版不引入 KMP、Kotlin/Native、複雜模組化或 network-first 架構。

### 1.1 Conversion Pipeline

Recommended pipeline:

```text
kautian.ods
  -> conversion tool
  -> dictionary_manifest.json
  -> dictionary_entries.jsonl
  -> dictionary-json-v1.zip
  -> bundled asset or remote download
  -> Android DictionaryImportService
  -> dictionary.sqlite
```

Conversion tool requirements:

- The first implementation should reuse `tool/build_dictionary_asset.py`.
- Python tooling remains the source of truth for ODS parsing rules.
- Must reuse the same sheet mapping rules documented in `android-native-migration-spec.md`.
- Must produce normalized `hokkienSearch` and `mandarinSearch` values before packaging.
- Must fail the build if required sheets are missing or if entry/sense/example counts are inconsistent.
- Must emit a manifest checksum so the Android app can reject partial or mismatched packages.

Selected approach:

- Keep ODS parsing outside Android runtime.
- Keep one converter implementation only.
- Android consumes generated `dictionary_manifest.json` and `dictionary_entries.jsonl`.
- If a future prebuilt `dictionary.sqlite` path is introduced, it must still be generated from the same Python conversion pipeline.
- Phase 1 package location is now `android-native/Generated/Dictionary`.
- That Android-local package is still the same platform-neutral manifest + JSONL output produced by the shared Python conversion pipeline.
- For long-term maintenance, prefer moving the generated package to a shared top-level generated path or publishing it as a CI artifact, so the generated artifact ownership is explicit across platforms.

### 1.2 Chinese Conversion Integration

Chinese conversion must be isolated behind `ChineseConversionService`.

Required implementation notes:

- Selected library: `https://github.com/xyrlsz/android-opencc`
- Dependency baseline: `com.github.xyrlsz:android-opencc:1.3.8`
- Search input uses `android-opencc` config `S2TWP`.
- Simplified Chinese display uses `android-opencc` config `TW2SP`.
- Keep `OpenCcInputGuard` before conversion so romanization-only text and invalid Unicode are returned unchanged.
- The Android app must not repeat the old Flutter plugin JNI crash pattern.
- `android-opencc` is JNI-backed, so wrap all conversion calls behind one adapter and make failure return original text.
- Call `ChineseConverter.init(context)` during app startup or first-use warmup instead of letting the first interactive search pay initialization cost.
- The library copies dictionary assets into app data on first conversion; when upgrading the library or its dictionaries, call `ChineseConverter.clearDictDataFolder()` once so stale extracted dictionaries do not persist across upgrades.
- The library requires JitPack and supports API 21+.

Suggested service boundary:

```kotlin
interface ChineseConversionService {
    suspend fun normalizeSearchInput(text: String, locale: AppLocale): String
    suspend fun translateForDisplay(text: String, locale: AppLocale): String
}
```

Acceptance checks:

- Romanization-only input such as `su-tian` is unchanged.
- Malformed Unicode is unchanged and does not crash.
- Simplified Chinese search terms normalize to Traditional/Taiwanese forms before repository lookup.
- `zh-CN` UI displays converted Simplified text without changing stored database rows.

Suggested adapter shape:

```kotlin
class AndroidOpenCcChineseConversionService(
    private val appContext: Context,
    private val dispatcher: CoroutineDispatcher
) : ChineseConversionService {
    suspend fun initialize()
}
```

Implementation notes for the adapter:

- Initialize `android-opencc` once.
- Serialize JNI conversion work or route it through a constrained dispatcher.
- Map product semantics directly to library configs:
  - search normalization: `S2TWP`
  - simplified display: `TW2SP`
- Preserve app-side fallback to original text on any conversion exception.

### 1.3 Typography and Font Fallback

Typography strategy must preserve Android nativeness while ensuring Tailo glyph coverage.

Current repository facts:

- Flutter currently bundles `assets/fonts/TauhuOo20.05-Regular.otf`.
- Flutter theme uses `TauhuOo` as fallback, not as the primary app font.

Selected approach:

- Keep system font as the default UI font.
- Bundle `TauhuOo` in the Android app as a fallback-capable asset.
- Do not switch Material typography wholesale to `TauhuOo`.
- Treat dictionary text fallback as a dedicated rendering concern.

Implementation notes:

- Add `tauhu_oo_regular` under Android font resources or equivalent packaged asset path.
- Prototype Android platform fallback support before broad UI implementation.
- Preferred path is a platform-backed fallback chain such as `Typeface.CustomFallbackBuilder` or an equivalent text resolver abstraction.
- If Compose cannot express the needed fallback chain directly through theme typography, introduce a narrow dictionary-text API instead of forcing a global font override.

Acceptance checks:

- Mixed Hanji + Tailo lines render without tofu.
- `o͘`, `ⁿ`, and common tone-mark combinations render correctly.
- Large text scale does not cause clipped ascenders/descenders.
- Search result rows, word detail, and reference articles stay visually native to Android.

## 2. Proposed Package Layout

```text
android-native/
  Generated/
    Dictionary/
      dictionary_manifest.json
      dictionary_entries.jsonl
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
            BookmarkStore.kt
          util/
            QueryNormalizer.kt
            TextNormalization.kt
            ByteFormatter.kt
            AsyncDebouncer.kt

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

        data/
          database/
            TaigiDictDatabase.kt
            DictionaryMigrations.kt
            DictionaryEntryEntity.kt
            DictionarySenseEntity.kt
            DictionaryExampleEntity.kt
            DictionaryMetadataEntity.kt
            DictionarySearchRow.kt
            DictionaryDao.kt
          import/
            DictionaryImportService.kt
            DictionaryJsonlReader.kt
            DictionaryManifest.kt
          repository/
            DictionaryRepository.kt
            PreferencesRepository.kt
          audio/
            ResumableDownloadService.kt
            AudioArchiveStore.kt
            AudioZipIndexService.kt
            AudioPlaybackService.kt
            OfflineAudioStore.kt
          conversion/
            AndroidOpenCcChineseConversionService.kt
            OpenCcInputGuard.kt

        feature/
          initialization/
            InitializationPhase.kt
            InitializationViewModel.kt
            InitializationScreen.kt
          dictionary/
            DictionarySearchViewModel.kt
            DictionaryScreen.kt
            DictionaryTwoPaneScreen.kt
            SearchBarSection.kt
            SearchHistorySection.kt
            EntryRow.kt
          worddetail/
            WordDetailViewModel.kt
            WordDetailScreen.kt
            WordDetailHeader.kt
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
            ResourceTile.kt
          info/
            AboutScreen.kt
            LicenseSummaryScreen.kt
            LicenseOverviewScreen.kt
            ReferenceArticleScreen.kt

        navigation/
          MainDestination.kt
          MainNavGraph.kt

        ui/
          text/
            DictionaryTextStyleResolver.kt
            TaigiFontFallback.kt
          theme/
            Color.kt
            Theme.kt
            Type.kt

      res/
        values/
        values-zh-rTW/
        values-zh-rCN/
        values-en/
        drawable/
        mipmap/
```

## 3. SQLite Schema Mapping

### 3.1 `dictionary_entries`

| SQLite column | Kotlin property | Type | Notes |
| --- | --- | --- | --- |
| `id` | `id` | `Long` | Primary key |
| `type` | `type` | `String` | 詞目類型 |
| `hanji` | `hanji` | `String` | 漢字詞頭 |
| `romanization` | `romanization` | `String` | 羅馬字 |
| `category` | `category` | `String` | 分類 |
| `audio_id` | `audioId` | `String` | 詞目音檔 id |
| `variant_chars` | `variantCharsJson` | `String` | JSON array |
| `word_synonyms` | `wordSynonymsJson` | `String` | JSON array |
| `word_antonyms` | `wordAntonymsJson` | `String` | JSON array |
| `alternative_pronunciations` | `alternativePronunciationsJson` | `String` | JSON array |
| `contracted_pronunciations` | `contractedPronunciationsJson` | `String` | JSON array |
| `colloquial_pronunciations` | `colloquialPronunciationsJson` | `String` | JSON array |
| `phonetic_differences` | `phoneticDifferencesJson` | `String` | JSON array |
| `vocabulary_comparisons` | `vocabularyComparisonsJson` | `String` | JSON array |
| `alias_target_entry_id` | `aliasTargetEntryId` | `Long?` | Alias target |
| `hokkien_search` | `hokkienSearch` | `String` | Normalized search index |
| `mandarin_search` | `mandarinSearch` | `String` | Normalized search index |

### 3.2 `dictionary_senses`

| SQLite column | Kotlin property | Type | Notes |
| --- | --- | --- | --- |
| `entry_id` | `entryId` | `Long` | Composite primary key |
| `sense_id` | `senseId` | `Long` | Composite primary key |
| `part_of_speech` | `partOfSpeech` | `String` | 詞性 |
| `definition` | `definition` | `String` | 解說 |
| `definition_synonyms` | `definitionSynonymsJson` | `String` | JSON array |
| `definition_antonyms` | `definitionAntonymsJson` | `String` | JSON array |

### 3.3 `dictionary_examples`

| SQLite column | Kotlin property | Type | Notes |
| --- | --- | --- | --- |
| `id` | `id` | `Long?` | Auto increment |
| `entry_id` | `entryId` | `Long` | Entry FK by convention |
| `sense_id` | `senseId` | `Long` | Sense id |
| `example_order` | `exampleOrder` | `Int` | Sorting |
| `hanji` | `hanji` | `String` | 例句漢字 |
| `romanization` | `romanization` | `String` | 例句羅馬字 |
| `mandarin` | `mandarin` | `String` | 華語 |
| `audio_id` | `audioId` | `String` | 例句音檔 id |

### 3.4 `dictionary_metadata`

| SQLite key | Meaning |
| --- | --- |
| `built_at` | DB build time in UTC ISO8601 |
| `source_modified_at` | Upstream ODS or converted package modified time in UTC ISO8601 |
| `entry_count` | Entry count |
| `sense_count` | Sense count |
| `example_count` | Example count |

## 4. Kotlin Domain Type Skeletons

```kotlin
data class DictionaryBundle(
    val entryCount: Int,
    val senseCount: Int,
    val exampleCount: Int,
    val entries: List<DictionaryEntry>,
    val databasePath: String?
) {
    val isDatabaseBacked: Boolean
        get() = databasePath != null
}

data class DictionaryEntry(
    val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    val audioId: String,
    val hokkienSearch: String,
    val mandarinSearch: String,
    val variantChars: List<String>,
    val wordSynonyms: List<String>,
    val wordAntonyms: List<String>,
    val alternativePronunciations: List<String>,
    val contractedPronunciations: List<String>,
    val colloquialPronunciations: List<String>,
    val phoneticDifferences: List<String>,
    val vocabularyComparisons: List<String>,
    val aliasTargetEntryId: Long?,
    val senses: List<DictionarySense>
) {
    val redirectsToPrimaryEntry: Boolean
        get() = aliasTargetEntryId != null

    val briefSummary: String
        get() {
            if (redirectsToPrimaryEntry) return ""
            return senses.firstOrNull { it.definition.isNotBlank() }?.definition
                ?: category.takeIf { it.isNotBlank() }
                ?: type.takeIf { it.isNotBlank() }
                ?: romanization
        }
}

data class DictionarySense(
    val partOfSpeech: String,
    val definition: String,
    val definitionSynonyms: List<String>,
    val definitionAntonyms: List<String>,
    val examples: List<DictionaryExample>
)

data class DictionaryExample(
    val hanji: String,
    val romanization: String,
    val mandarin: String,
    val audioId: String
)

data class PreparedWordDetail(
    val entry: DictionaryEntry,
    val resolvedEntryId: Long,
    val openableWords: Set<String>
) {
    fun canOpenWord(word: String): Boolean = word in openableWords
}
```

## 5. Room Entity / DAO Skeletons

```kotlin
@Entity(tableName = "dictionary_entries")
data class DictionaryEntryEntity(
    @PrimaryKey val id: Long,
    val type: String,
    val hanji: String,
    val romanization: String,
    val category: String,
    @ColumnInfo(name = "audio_id") val audioId: String,
    @ColumnInfo(name = "variant_chars") val variantCharsJson: String,
    @ColumnInfo(name = "word_synonyms") val wordSynonymsJson: String,
    @ColumnInfo(name = "word_antonyms") val wordAntonymsJson: String,
    @ColumnInfo(name = "alternative_pronunciations") val alternativePronunciationsJson: String,
    @ColumnInfo(name = "contracted_pronunciations") val contractedPronunciationsJson: String,
    @ColumnInfo(name = "colloquial_pronunciations") val colloquialPronunciationsJson: String,
    @ColumnInfo(name = "phonetic_differences") val phoneticDifferencesJson: String,
    @ColumnInfo(name = "vocabulary_comparisons") val vocabularyComparisonsJson: String,
    @ColumnInfo(name = "alias_target_entry_id") val aliasTargetEntryId: Long?,
    @ColumnInfo(name = "hokkien_search") val hokkienSearch: String,
    @ColumnInfo(name = "mandarin_search") val mandarinSearch: String
)

@Entity(
    tableName = "dictionary_senses",
    primaryKeys = ["entry_id", "sense_id"]
)
data class DictionarySenseEntity(
    @ColumnInfo(name = "entry_id") val entryId: Long,
    @ColumnInfo(name = "sense_id") val senseId: Long,
    @ColumnInfo(name = "part_of_speech") val partOfSpeech: String,
    val definition: String,
    @ColumnInfo(name = "definition_synonyms") val definitionSynonymsJson: String,
    @ColumnInfo(name = "definition_antonyms") val definitionAntonymsJson: String
)

@Entity(tableName = "dictionary_examples")
data class DictionaryExampleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(name = "entry_id") val entryId: Long,
    @ColumnInfo(name = "sense_id") val senseId: Long,
    @ColumnInfo(name = "example_order") val exampleOrder: Int,
    val hanji: String,
    val romanization: String,
    val mandarin: String,
    @ColumnInfo(name = "audio_id") val audioId: String
)

@Dao
interface DictionaryDao {
    @RawQuery
    suspend fun searchIds(query: SupportSQLiteQuery): List<Long>

    @Query("SELECT * FROM dictionary_entries WHERE id = :id")
    suspend fun entry(id: Long): DictionaryEntryEntity?

    @Query("SELECT * FROM dictionary_entries WHERE id IN (:ids)")
    suspend fun entries(ids: List<Long>): List<DictionaryEntryEntity>
}
```

## 6. Repository Contract

```kotlin
interface DictionaryRepository {
    suspend fun loadBundle(): DictionaryBundle
    suspend fun search(rawQuery: String, limit: Int, offset: Int): List<DictionaryEntry>
    suspend fun findLinkedEntry(rawWord: String): DictionaryEntry?
    suspend fun entries(ids: List<Long>): List<DictionaryEntry>
    suspend fun entry(id: Long): DictionaryEntry?
    fun clearBundleCache()
}
```

### Required SQL Search Query

```sql
SELECT id
FROM dictionary_entries
WHERE hanji LIKE ? ESCAPE '\\'
   OR hokkien_search LIKE ? ESCAPE '\\'
   OR mandarin_search LIKE ? ESCAPE '\\'
   OR EXISTS (
     SELECT 1
     FROM dictionary_senses
     WHERE dictionary_senses.entry_id = dictionary_entries.id
       AND dictionary_senses.definition LIKE ? ESCAPE '\\'
   )
   OR EXISTS (
     SELECT 1
     FROM dictionary_examples
     WHERE dictionary_examples.entry_id = dictionary_entries.id
       AND (
         dictionary_examples.hanji LIKE ? ESCAPE '\\'
         OR dictionary_examples.mandarin LIKE ? ESCAPE '\\'
       )
   )
ORDER BY
  CASE
    WHEN hanji = ? THEN 0
    WHEN hokkien_search LIKE ? ESCAPE '\\' THEN 1
    WHEN hanji LIKE ? ESCAPE '\\' THEN 1
    ELSE 2
  END ASC,
  length(hokkien_search) ASC,
  id ASC
LIMIT ? OFFSET ?
```

## 7. ViewModel Contracts

### `DictionarySearchViewModel`

```kotlin
class DictionarySearchViewModel(
    private val repository: DictionaryRepository,
    private val conversionService: ChineseConversionService,
    private val bookmarkStore: BookmarkStore
) : ViewModel() {
    val uiState: StateFlow<DictionarySearchUiState>

    fun load()
    fun onSearchTextChange(value: String)
    fun submitQuery()
    fun applyHistoryQuery(query: String)
    fun clearSearchHistory()
    fun selectEntry(entry: DictionaryEntry)
}
```

Acceptance criteria:

- Empty query clears results immediately.
- Non-empty query waits 300 ms before searching.
- A newer query cancels any pending or running older search.
- History saves only when results are non-empty.
- History max count is 10.

### `WordDetailViewModel`

```kotlin
class WordDetailViewModel(
    private val repository: DictionaryRepository,
    private val bookmarkStore: BookmarkStore,
    private val audioStore: OfflineAudioStore,
    private val conversionService: ChineseConversionService
) : ViewModel() {
    val uiState: StateFlow<WordDetailUiState>

    fun prepare(entry: DictionaryEntry)
    fun toggleBookmark()
    fun playWordAudio()
    fun playExampleAudio(example: DictionaryExample)
    fun openLinkedWord(word: String)
    fun buildShareText(): String
}
```

Acceptance criteria:

- Alias entries resolve before display.
- Openable chips exclude links pointing back to current resolved entry.
- Share text matches Flutter format.
- Audio errors surface as user-visible messages.

### `InitializationViewModel`

```kotlin
class InitializationViewModel(
    private val importService: DictionaryImportService,
    private val preferencesStore: AppPreferencesStore,
    private val resourceStore: OfflineDictionaryResourceStore
) : ViewModel() {
    val uiState: StateFlow<InitializationUiState>

    fun start()
    fun retry()
    fun rebuild()
}
```

Acceptance criteria:

- App cannot enter main tabs until `isReady == true`.
- Rebuild success increments `databaseGeneration`.
- Corrupted converted dictionary package deletes source and attempts redownload.

## 8. Technical Spikes Required Up Front

### Spike A: ODS Conversion Ownership

Goal:

- Verify `tool/build_dictionary_asset.py` can remain the only conversion entry point for Android native.

What to confirm:

- JSONL package shape is stable enough for Android import.
- Generated manifest contains all metadata Android rebuild needs.
- CI can package generated output into Android-consumable assets or release artifacts.
- Reusing the copied package under `android-native/Generated/Dictionary` does not drift from the shared Python-generated source data.

Exit criteria:

- No Kotlin ODS parser is needed for Phase 1.
- Android can consume the generated manifest + JSONL package from `android-native/Generated/Dictionary` before a shared generated path is introduced.

### Spike B: Font Fallback Feasibility

Goal:

- Verify Android can render system-font-first dictionary text with bundled `TauhuOo` fallback.

What to confirm:

- Compose path for fallback is sufficient, or a platform text adapter is required.
- Fallback works for Tailo / POJ special characters in search rows and detail content.
- Line height, truncation, and selection remain acceptable.

Exit criteria:

- Choose one implementation path:
  - direct Compose-compatible fallback chain
  - platform `Typeface` adapter
  - segmented dictionary text rendering helper

### Spike C: android-opencc Integration Safety

Goal:

- Verify `android-opencc` can satisfy product semantics without reproducing the old Flutter JNI crash behavior.

What to confirm:

- `S2TWP` and `TW2SP` outputs match expected product behavior for representative queries and detail text.
- `ChineseConverter.init(context)` can be safely warmed up before the first search interaction.
- App-side `OpenCcInputGuard` plus serialized conversion execution is sufficient for malformed Unicode and rapid repeated calls.
- Upgrade flow for extracted dictionary assets is understood and covered by `clearDictDataFolder()` when needed.

Exit criteria:

- `android-opencc` remains the selected library with a documented initialization and failure-handling policy.

## 9. Workstream Breakdown

### Workstream 1: Project Shell

Scope:

- Create Android app shell.
- Add top-level navigation with Dictionary / Bookmarks / Settings.
- Add shared app container and locale/theme stores.

Deliverables:

- `MainActivity.kt`
- `TaigiDictApplication.kt`
- `MainNavGraph.kt`
- Basic locale/theme settings stores.

Acceptance criteria:

- App launches to initialization gate.
- Top-level navigation is visible after mocked ready state.

### Workstream 2: Database Layer

Scope:

- Add Room.
- Implement migrations.
- Implement entities and model mapping.
- Implement read-only repository APIs.

Deliverables:

- `TaigiDictDatabase.kt`
- `DictionaryMigrations.kt`
- entity classes
- `DictionaryRepository.kt`

Acceptance criteria:

- Can open an existing `dictionary.sqlite`.
- Can load metadata counts.
- Can load entries by ids preserving requested order.

### Workstream 3: Search Parity

Scope:

- Port normalization.
- Port SQL search.
- Port linked entry lookup.

Deliverables:

- `QueryNormalizer.kt`
- `DictionarySearchService.kt`
- unit tests for normalization and ranking.

Acceptance criteria:

- `Tsìt4-tsi̍t8/【狗】` normalizes to `tsit tsit 狗`.
- Exact headword ranks before longer headword and definition matches.
- Linked lookup prefers exact hanji, variant, then romanization.

### Workstream 4: Dictionary UI

Scope:

- Search screen.
- Search history.
- Entry rows.
- Phone detail navigation.
- Tablet list-detail layout.

Deliverables:

- `DictionarySearchViewModel.kt`
- `DictionaryScreen.kt`
- `DictionaryTwoPaneScreen.kt`
- `EntryRow.kt`

Acceptance criteria:

- 300 ms debounce.
- Clear button clears query and results.
- Phone pushes detail.
- Tablet uses list-detail layout.

### Workstream 5: Word Detail

Scope:

- Detail screen.
- Alias resolve integration.
- Definition links.
- Relationship chips.
- Share text.

Deliverables:

- `WordDetailViewModel.kt`
- `WordDetailScreen.kt`
- `SenseSection.kt`
- `RelationshipChipRow.kt`

Acceptance criteria:

- Definition `【詞】` renders as tappable text.
- Linked word opens target entry.
- Bookmark button updates immediately.
- Share output matches Flutter format.

### Workstream 6: Bookmarks

Scope:

- Bookmark persistence.
- Bookmark list/grid.
- Entry lookup.

Deliverables:

- `BookmarkStore.kt`
- `BookmarksViewModel.kt`
- `BookmarksScreen.kt`

Acceptance criteria:

- Toggle bookmark persists through app restart.
- Empty state appears when no bookmarks.
- Tablet uses adaptive grid when space allows.

### Workstream 7: Offline Resources

Scope:

- Dictionary source resource state.
- Resumable downloads.
- Audio archive store.
- Zip index and clip extraction.
- Audio playback.

Deliverables:

- `ResumableDownloadService.kt`
- `AudioArchiveStore.kt`
- `AudioZipIndexService.kt`
- `AudioPlaybackService.kt`
- `OfflineAudioStore.kt`

Acceptance criteria:

- Download can pause/resume.
- Completed archive validates sample clip id.
- Playing a clip extracts only that mp3 to cache.
- Tapping current clip stops playback.

### Workstream 8: Converted Dictionary Rebuild

Scope:

- Implement JSONL dictionary package reader.
- Validate `dictionary_manifest.json`.
- Streaming decode converted entries.
- Write SQLite in chunks.
- Emit progress.

Deliverables:

- `DictionaryJsonlReader.kt`
- `DictionaryManifest.kt`
- `DictionaryImportService.kt`
- import tests with fixture JSONL package.

Acceptance criteria:

- Missing manifest produces typed error.
- Empty or malformed JSONL produces corrupted source error.
- Manifest counts match imported SQLite counts.
- Rebuild writes metadata and all expected tables.

### Workstream 9: Settings and Static Content

Scope:

- Settings form.
- Advanced maintenance.
- About.
- License summary.
- Reference articles.

Deliverables:

- `SettingsScreen.kt`
- `AdvancedSettingsScreen.kt`
- `AboutScreen.kt`
- `LicenseSummaryScreen.kt`
- `ReferenceArticleScreen.kt`

Acceptance criteria:

- Theme, locale, and text scale persist.
- Rebuild confirmation appears before rebuild.
- Reference articles render paragraphs, bullets, and tables.

## 10. Testing Matrix

### Unit Tests

- Query normalization.
- Search ranking.
- Linked entry lookup.
- Alias resolve.
- Share text generation.
- OpenCC input guard.
- `android-opencc` adapter config mapping and failure fallback.
- Font fallback resolver for mixed-script text.
- Bookmark persistence.
- Text scale snapping.
- Download snapshot transitions.
- Zip index parsing.

### Integration Tests

- Open bundled SQLite and run search.
- Open word detail from search result.
- Toggle bookmark and verify bookmark tab.
- Change locale and verify display conversion.
- Verify `android-opencc` initialization does not block the first interactive search path unexpectedly.
- Render mixed Hanji + Tailo entry content with fallback-enabled text path.
- Simulate failed initialization and retry.

### UI Tests

- Phone dictionary search.
- Phone word detail.
- Tablet list-detail layout.
- Settings form.
- Mixed-script dictionary rows with fallback glyph coverage.
- Resource download tile states.

## 11. Initial Build Order

1. Create Android shell and app container.
2. Confirm ODS conversion ownership around `tool/build_dictionary_asset.py`.
3. Spike font fallback feasibility with bundled `TauhuOo`.
4. Add Room and schema migrations.
5. Port models and repository read APIs.
6. Port normalization and search.
7. Build dictionary search UI.
8. Build word detail UI.
9. Add bookmarks.
10. Add settings.
11. Spike `android-opencc` initialization and failure-handling behavior.
12. Add `ChineseConversionService` with `android-opencc` adapter.
13. Add audio and download services.
14. Add converted dictionary package rebuild.
