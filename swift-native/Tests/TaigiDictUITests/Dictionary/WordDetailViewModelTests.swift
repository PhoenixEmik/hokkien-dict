import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class WordDetailViewModelTests: XCTestCase {
    func testPrepareResolvesAliasChainBeforeDisplay() async {
        let alias = entry(id: 1, hanji: "字典", romanization: "jī-tián", aliasTargetEntryID: 2)
        let primary = entry(id: 2, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        let repository = InMemoryRepository(entries: [alias, primary])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))
        _ = await viewModel.prepare(entry: alias)

        XCTAssertEqual(viewModel.entry?.id, 2)
        XCTAssertEqual(viewModel.resolvedEntryID, 2)
        XCTAssertEqual(viewModel.shareText(), "辭典\nsû-tián\n工具書")
    }

    func testPrepareMarksOnlyExternalLinkedRelationshipWordsOpenable() async {
        let primary = entry(
            id: 1,
            hanji: "辭典",
            romanization: "sû-tián",
            variantChars: ["辭典"],
            wordSynonyms: ["字典", "無此詞"]
        )
        let linked = entry(id: 2, hanji: "字典", romanization: "jī-tián")
        let repository = InMemoryRepository(entries: [primary, linked])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))
        _ = await viewModel.prepare(entry: primary)

        XCTAssertEqual(viewModel.openableWords, ["字典"])
    }

    func testPrepareDoesNotOpenLinkedRelationshipWordWithoutSenses() async {
        let primary = entry(
            id: 1,
            hanji: "有義項",
            romanization: "ū-gī-hāng",
            wordSynonyms: ["無義項"]
        )
        let linkedWithoutSenses = entry(
            id: 2,
            hanji: "無義項",
            romanization: "bô-gī-hāng",
            hasSenses: false
        )
        let repository = InMemoryRepository(entries: [primary, linkedWithoutSenses])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)

        XCTAssertFalse(viewModel.openableWords.contains("無義項"))
        let linkedEntry = await viewModel.linkedEntry(for: "無義項")
        XCTAssertNil(linkedEntry)
    }

    func testPlayWordAudioUpdatesAudioMessage() async {
        let primary = entry(id: 10, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        var withAudio = primary
        withAudio.audioID = "1(1)"

        let repository = InMemoryRepository(entries: [withAudio])
        let audioStore = TestOfflineAudioManager()
        let viewModel = WordDetailViewModel(
            library: DictionaryLibrary(repository: repository),
            offlineAudioStore: audioStore
        )

        _ = await viewModel.prepare(entry: withAudio)
        await viewModel.playWordAudio()

        XCTAssertEqual(viewModel.audioMessage, "播放中")
    }

    func testPrepareSimplifiedLocaleTranslatesDisplayAndLinkedLookup() async {
        let primary = entry(
            id: 1,
            hanji: "辭典",
            romanization: "sû-tián",
            definition: "工具書",
            wordSynonyms: ["字典"]
        )
        let linked = entry(id: 2, hanji: "字典", romanization: "jī-tián")
        let repository = InMemoryRepository(entries: [primary, linked])
        let conversion = TestChineseConversionProvider(
            normalizedQueryMap: ["字典": "字典"],
            displayMap: ["辭典": "辞典", "工具書": "工具书", "字典": "字典", "名詞": "名词"]
        )
        let viewModel = WordDetailViewModel(
            library: DictionaryLibrary(repository: repository),
            conversionService: conversion
        )

        await viewModel.prepare(entry: primary, locale: .simplifiedChinese)

        XCTAssertEqual(viewModel.entry?.hanji, "辞典")
        XCTAssertEqual(viewModel.shareText(), "辞典\nsû-tián\n工具书")
        XCTAssertTrue(viewModel.openableWords.contains("字典"))

        let linkedEntry = await viewModel.linkedEntry(for: "字典", locale: .simplifiedChinese)
        XCTAssertEqual(linkedEntry?.id, 2)
    }

    func testPlayWordAudioClipNotFoundShowsFriendlyMessage() async {
        var withAudio = entry(id: 10, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        withAudio.audioID = "missing-clip"

        let repository = InMemoryRepository(entries: [withAudio])
        let audioStore = MissingClipOfflineAudioManager()
        let viewModel = WordDetailViewModel(
            library: DictionaryLibrary(repository: repository),
            offlineAudioStore: audioStore
        )

        _ = await viewModel.prepare(entry: withAudio)
        await viewModel.playWordAudio()

        XCTAssertEqual(
            viewModel.audioMessage,
            "播放失敗：找不到離線音檔。請先在設定下載或重新下載離線音訊資源。"
        )
    }
}

private actor TestChineseConversionProvider: ChineseConversionProviding {
    private let normalizedQueryMap: [String: String]
    private let displayMap: [String: String]

    init(normalizedQueryMap: [String: String], displayMap: [String: String]) {
        self.normalizedQueryMap = normalizedQueryMap
        self.displayMap = displayMap
    }

    func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String {
        normalizedQueryMap[text] ?? text
    }

    func translateForDisplay(_ text: String, locale: AppLocale) async -> String {
        displayMap[text] ?? text
    }
}

private actor TestOfflineAudioManager: OfflineAudioManaging {
    private var playingClipID: String?

    func snapshot(for type: AudioArchiveType) async -> DownloadSnapshot {
        DownloadSnapshot(state: .idle)
    }

    func startDownload(_ type: AudioArchiveType) async {}
    func pauseDownload(_ type: AudioArchiveType) async {}
    func resumeDownload(_ type: AudioArchiveType) async {}
    func restartDownload(_ type: AudioArchiveType) async {}

    func playClip(_ clipID: String, from type: AudioArchiveType) async throws {
        let fullID = "\(type.rawValue):\(clipID)"
        if playingClipID == fullID {
            playingClipID = nil
        } else {
            playingClipID = fullID
        }
    }

    func currentlyPlayingClipID() async -> String? {
        playingClipID
    }
}

private actor MissingClipOfflineAudioManager: OfflineAudioManaging {
    func snapshot(for type: AudioArchiveType) async -> DownloadSnapshot {
        DownloadSnapshot(state: .completed, downloadedBytes: 100, totalBytes: 100)
    }

    func startDownload(_ type: AudioArchiveType) async {}
    func pauseDownload(_ type: AudioArchiveType) async {}
    func resumeDownload(_ type: AudioArchiveType) async {}
    func restartDownload(_ type: AudioArchiveType) async {}

    func playClip(_ clipID: String, from type: AudioArchiveType) async throws {
        throw AudioZipIndexError.clipNotFound(clipID)
    }

    func currentlyPlayingClipID() async -> String? {
        nil
    }
}

private actor InMemoryRepository: DictionaryRepositoryProtocol {
    private let bundle: DictionaryBundle
    private let repository: InMemoryDictionaryRepository

    init(entries: [DictionaryEntry]) {
        bundle = DictionaryBundle(
            entryCount: entries.count,
            senseCount: entries.reduce(0) { $0 + $1.senses.count },
            exampleCount: 0,
            entries: entries
        )
        repository = InMemoryDictionaryRepository(bundle: bundle)
    }

    func loadBundle() async throws -> DictionaryBundle {
        bundle
    }

    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry] {
        let results = await repository.search(rawQuery, limit: limit + max(offset, 0))
        return Array(results.dropFirst(max(offset, 0)))
    }

    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        await repository.findLinkedEntry(rawWord)
    }

    func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        await repository.entries(ids: ids)
    }

    func entry(id: Int64) async throws -> DictionaryEntry? {
        await repository.entry(id: id)
    }

    func clearBundleCache() async {}
}

private func entry(
    id: Int64,
    hanji: String,
    romanization: String,
    definition: String = "",
    variantChars: [String] = [],
    wordSynonyms: [String] = [],
    aliasTargetEntryID: Int64? = nil,
    hasSenses: Bool = true
) -> DictionaryEntry {
    DictionaryEntry(
        id: id,
        type: "名詞",
        hanji: hanji,
        romanization: romanization,
        category: "主詞目",
        audioID: "",
        hokkienSearch: "\(hanji) \(romanization)",
        mandarinSearch: definition,
        variantChars: variantChars,
        wordSynonyms: wordSynonyms,
        aliasTargetEntryID: aliasTargetEntryID,
        senses: hasSenses ? [
            DictionarySense(partOfSpeech: "名詞", definition: definition),
        ] : []
    )
}
