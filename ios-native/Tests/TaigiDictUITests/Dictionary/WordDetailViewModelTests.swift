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

    func testPrepareKeepsSourceEntryVisibleWhileResolvingDetail() async {
        let first = entry(id: 1, hanji: "先前", romanization: "sing-tsîng", definition: "原本的詞條")
        let alias = entry(id: 2, hanji: "字典", romanization: "jī-tián", aliasTargetEntryID: 3)
        let primary = entry(id: 3, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        let repository = InMemoryRepository(
            entries: [first, alias, primary],
            entryLookupDelayNanoseconds: 100_000_000
        )
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: first)
        let prepareTask = Task {
            await viewModel.prepare(entry: alias)
        }
        await Task.yield()

        XCTAssertEqual(viewModel.entry?.id, 2)
        XCTAssertEqual(viewModel.resolvedEntryID, 2)

        await prepareTask.value
        XCTAssertEqual(viewModel.entry?.id, 3)
        XCTAssertEqual(viewModel.resolvedEntryID, 3)
    }

    func testPrepareCancellationDoesNotSurfaceAsLoadFailure() async {
        let source = entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        let repository = CancellationDetailRepository(entries: [source])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: source)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.entry?.id, 1)
        XCTAssertEqual(viewModel.resolvedEntryID, 1)
    }

    func testClearResetsPreparedEntryState() async {
        let primary = entry(
            id: 1,
            hanji: "辭典",
            romanization: "sû-tián",
            definition: "工具書",
            wordSynonyms: ["字典"]
        )
        let linked = entry(id: 2, hanji: "字典", romanization: "jī-tián")
        let repository = InMemoryRepository(entries: [primary, linked])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)
        viewModel.clear()

        XCTAssertNil(viewModel.entry)
        XCTAssertNil(viewModel.resolvedEntryID)
        XCTAssertTrue(viewModel.openableWords.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.shareText(), "")
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

    func testLinkedEntryReturnsOpenableRelationshipEntry() async {
        let primary = entry(
            id: 1,
            hanji: "完全",
            romanization: "uân-tsuân",
            wordAntonyms: ["無全"]
        )
        let linked = entry(id: 2, hanji: "無全", romanization: "bô-tsuân")
        let repository = InMemoryRepository(entries: [primary, linked])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)
        let linkedEntry = await viewModel.linkedEntry(for: "無全")

        XCTAssertEqual(linkedEntry?.id, 2)
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

    func testPrepareOpensLinkedRelationshipWordWhenAliasTargetHasSenses() async {
        let primary = entry(
            id: 1,
            hanji: "烏",
            romanization: "oo",
            wordAntonyms: ["白"]
        )
        let alias = entry(
            id: 2,
            hanji: "白",
            romanization: "pe̍h",
            aliasTargetEntryID: 3,
            hasSenses: false
        )
        let target = entry(
            id: 3,
            hanji: "白",
            romanization: "pe̍h",
            definition: "白色。"
        )
        let repository = InMemoryRepository(entries: [primary, alias, target])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)

        XCTAssertTrue(viewModel.openableWords.contains("白"))
        let linkedEntry = await viewModel.linkedEntry(for: "白")
        XCTAssertEqual(linkedEntry?.id, 3)
    }

    func testPrepareOpensLinkedRelationshipWordWithBracketAnnotation() async {
        let primary = entry(
            id: 1,
            hanji: "烏",
            romanization: "oo",
            wordAntonyms: ["白【替】"]
        )
        let target = entry(
            id: 2,
            hanji: "白",
            romanization: "pe̍h",
            definition: "白色。"
        )
        let repository = InMemoryRepository(entries: [primary, target])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)

        XCTAssertTrue(viewModel.openableWords.contains("白【替】"))
        let linkedEntry = await viewModel.linkedEntry(for: "白【替】")
        XCTAssertEqual(linkedEntry?.id, 2)
    }

    func testPrepareMarksLinkedWordOpenableWhenAnyExactCandidateIsDisplayable() async {
        let primary = entry(
            id: 1,
            hanji: "烏",
            romanization: "oo",
            wordAntonyms: ["白"]
        )
        let emptyDuplicate = entry(
            id: 2,
            hanji: "白",
            romanization: "pe̍h",
            hasSenses: false
        )
        let displayableDuplicate = entry(
            id: 3,
            hanji: "白",
            romanization: "pe̍h",
            definition: "白色。"
        )
        let repository = InMemoryRepository(entries: [primary, emptyDuplicate, displayableDuplicate])
        let viewModel = WordDetailViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.prepare(entry: primary)

        XCTAssertTrue(viewModel.openableWords.contains("白"))
        let linkedEntry = await viewModel.linkedEntry(for: "白")
        XCTAssertEqual(linkedEntry?.id, 3)
    }

    func testPrepareOpensActualPackageAntonymForWhiteAndBlack() async throws {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let generatedDirectory = packageRoot.appendingPathComponent("Generated/Dictionary")
        let manifestURL = generatedDirectory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw XCTSkip("Generated dictionary package is not present.")
        }

        let repository = PackageDictionaryRepository(packageDirectory: generatedDirectory)
        let library = DictionaryLibrary(repository: repository)
        let whiteResults = try await repository.search("白", limit: 5, offset: 0)
        let whiteEntry = try XCTUnwrap(whiteResults.first(where: { $0.id == 1850 }))
        let viewModel = WordDetailViewModel(library: library)

        await viewModel.prepare(entry: whiteEntry)

        XCTAssertTrue(viewModel.openableWords.contains("烏"))
        let linkedEntry = await viewModel.linkedEntry(for: "烏")
        XCTAssertEqual(linkedEntry?.id, 6227)
    }

    func testPrepareOpensActualPackageAntonymForBlackAndWhite() async throws {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let generatedDirectory = packageRoot.appendingPathComponent("Generated/Dictionary")
        let manifestURL = generatedDirectory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw XCTSkip("Generated dictionary package is not present.")
        }

        let repository = PackageDictionaryRepository(packageDirectory: generatedDirectory)
        let library = DictionaryLibrary(repository: repository)
        let blackResults = try await repository.search("烏", limit: 10, offset: 0)
        let blackEntry = try XCTUnwrap(blackResults.first(where: { $0.id == 6227 }))
        let viewModel = WordDetailViewModel(library: library)

        await viewModel.prepare(entry: blackEntry)

        XCTAssertTrue(viewModel.openableWords.contains("白"))
        let linkedEntry = await viewModel.linkedEntry(for: "白")
        XCTAssertEqual(linkedEntry?.id, 1850)
    }

    func testPrepareOpensActualInstalledPackageAntonymForBlackAndWhite() async throws {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let generatedDirectory = packageRoot.appendingPathComponent("Generated/Dictionary")
        let manifestURL = generatedDirectory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw XCTSkip("Generated dictionary package is not present.")
        }

        let installedDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WordDetailViewModelTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: installedDirectory) }

        let repository = InstalledDictionaryRepository(
            sourceDirectory: generatedDirectory,
            installedDirectory: installedDirectory
        )
        let library = DictionaryLibrary(repository: repository)
        let blackResults = try await repository.search("烏", limit: 10, offset: 0)
        let blackEntry = try XCTUnwrap(blackResults.first(where: { $0.id == 6227 }))
        let viewModel = WordDetailViewModel(library: library)

        await viewModel.prepare(entry: blackEntry)

        XCTAssertTrue(viewModel.openableWords.contains("白"))
        let linkedEntry = await viewModel.linkedEntry(for: "白")
        XCTAssertEqual(linkedEntry?.id, 1850)
    }

    func testPlayWordAudioSuccessClearsAudioAlert() async {
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

        XCTAssertNil(viewModel.audioAlertMessage)
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

    func testPlayWordAudioClipNotFoundShowsFriendlyAlert() async {
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
            viewModel.audioAlertMessage,
            "離線音訊資源尚未準備好，請先在設定下載離線音訊資源。"
        )
    }

    func testPlayExampleAudioUsesSameFriendlyAlertBehavior() async {
        let example = DictionaryExample(
            hanji: "阿媽",
            romanization: "a-má",
            mandarin: "外婆或奶奶",
            audioID: "missing-example"
        )
        let primary = entry(id: 10, hanji: "辭典", romanization: "sû-tián", definition: "工具書")
        let repository = InMemoryRepository(entries: [primary])
        let audioStore = MissingClipOfflineAudioManager()
        let viewModel = WordDetailViewModel(
            library: DictionaryLibrary(repository: repository),
            offlineAudioStore: audioStore
        )

        _ = await viewModel.prepare(entry: primary)
        await viewModel.playExampleAudio(example)

        XCTAssertEqual(
            viewModel.audioAlertMessage,
            "離線音訊資源尚未準備好，請先在設定下載離線音訊資源。"
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

private actor CancellationDetailRepository: DictionaryRepositoryProtocol {
    private let bundle: DictionaryBundle

    init(entries: [DictionaryEntry]) {
        bundle = DictionaryBundle(
            entryCount: entries.count,
            senseCount: entries.reduce(0) { $0 + $1.senses.count },
            exampleCount: 0,
            entries: entries
        )
    }

    func loadBundle() async throws -> DictionaryBundle {
        bundle
    }

    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry] {
        []
    }

    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        throw CancellationError()
    }

    func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        []
    }

    func entry(id: Int64) async throws -> DictionaryEntry? {
        bundle.entries.first { $0.id == id }
    }

    func clearBundleCache() async {}
}

private actor InMemoryRepository: DictionaryRepositoryProtocol {
    private let bundle: DictionaryBundle
    private let repository: InMemoryDictionaryRepository
    private let entryLookupDelayNanoseconds: UInt64

    init(entries: [DictionaryEntry], entryLookupDelayNanoseconds: UInt64 = 0) {
        bundle = DictionaryBundle(
            entryCount: entries.count,
            senseCount: entries.reduce(0) { $0 + $1.senses.count },
            exampleCount: 0,
            entries: entries
        )
        repository = InMemoryDictionaryRepository(bundle: bundle)
        self.entryLookupDelayNanoseconds = entryLookupDelayNanoseconds
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
        if entryLookupDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: entryLookupDelayNanoseconds)
        }
        return await repository.entry(id: id)
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
    wordAntonyms: [String] = [],
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
        wordAntonyms: wordAntonyms,
        aliasTargetEntryID: aliasTargetEntryID,
        senses: hasSenses ? [
            DictionarySense(partOfSpeech: "名詞", definition: definition),
        ] : []
    )
}
