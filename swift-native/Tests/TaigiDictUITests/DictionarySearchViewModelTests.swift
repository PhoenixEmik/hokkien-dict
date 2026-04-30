import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class DictionarySearchViewModelTests: XCTestCase {
    func testSubmitSearchUpdatesResultsAndHistory() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: TestSearchHistoryStore()
        )
        await viewModel.load()

        viewModel.searchText = "辭典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.results.map(\.id), [1])
        XCTAssertEqual(viewModel.searchHistory, ["辭典"])
    }

    func testEmptyScheduledSearchClearsResults() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: TestSearchHistoryStore()
        )
        await viewModel.load()

        viewModel.searchText = "辭典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))
        viewModel.searchText = ""
        viewModel.scheduleSearch()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertNil(viewModel.selectedEntry)
    }

    func testResetAfterMaintenanceClearsSearchStateAndResetsLibrary() async {
        let repository = MaintenanceAwareRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: TestSearchHistoryStore()
        )
        await viewModel.load()

        viewModel.searchText = "辭典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(viewModel.results.isEmpty)

        await viewModel.resetAfterMaintenance()
        let clearCacheCount = await repository.clearCacheCount

        XCTAssertEqual(clearCacheCount, 1)
        XCTAssertEqual(viewModel.libraryPhase, .idle)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertNil(viewModel.selectedEntry)
        XCTAssertNil(viewModel.detailEntry)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitSearchNormalizesSimplifiedInputAndTranslatesDisplay() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let conversion = TestChineseConversionProvider(
            normalizedQueryMap: ["辞典": "辭典"],
            displayMap: ["辭典": "辞典", "工具書": "工具书", "名詞": "名词"]
        )
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            appLocale: .simplifiedChinese,
            conversionService: conversion,
            searchHistoryStore: TestSearchHistoryStore()
        )
        await viewModel.load()

        viewModel.searchText = "辞典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.results.map(\.hanji), ["辞典"])
        XCTAssertEqual(viewModel.results.first?.briefSummary, "工具书")
    }

    func testLoadHydratesSearchHistoryFromStore() async {
        let repository = InMemoryRepository(entries: [])
        let historyStore = TestSearchHistoryStore(initialValues: [" 辭典 ", "辭典", "", "字典"])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: historyStore
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.searchHistory, ["辭典", "字典"])
    }

    func testSubmitSearchPersistsHistoryToStore() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let historyStore = TestSearchHistoryStore(initialValues: ["字典"])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: historyStore
        )
        await viewModel.load()

        viewModel.searchText = "辭典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))

        let persisted = await historyStore.load()
        XCTAssertEqual(persisted, ["辭典", "字典"])
    }

    func testClearSearchHistoryAlsoClearsStore() async {
        let repository = InMemoryRepository(entries: [])
        let historyStore = TestSearchHistoryStore(initialValues: ["辭典", "字典"])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: historyStore
        )
        await viewModel.load()

        await viewModel.clearSearchHistory()

        XCTAssertTrue(viewModel.searchHistory.isEmpty)
        let persisted = await historyStore.load()
        XCTAssertEqual(persisted, [])
    }

    func testCancelledSearchDoesNotShowFailureMessage() async {
        let repository = CancellingSearchRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let viewModel = DictionarySearchViewModel(
            repository: repository,
            searchHistoryStore: TestSearchHistoryStore()
        )
        await viewModel.load()

        viewModel.searchText = "辭典"
        viewModel.submitSearch()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertTrue(viewModel.results.isEmpty)
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

private actor TestSearchHistoryStore: SearchHistoryStoring {
    private var values: [String]

    init(initialValues: [String] = []) {
        values = initialValues
    }

    func load() async -> [String] {
        values
    }

    func save(_ history: [String]) async {
        values = history
    }

    func clear() async {
        values = []
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

private actor MaintenanceAwareRepository: DictionaryRepositoryProtocol {
    private let bundle: DictionaryBundle
    private let repository: InMemoryDictionaryRepository

    var clearCacheCount = 0

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

    func clearBundleCache() async {
        clearCacheCount += 1
    }
}

private actor CancellingSearchRepository: DictionaryRepositoryProtocol {
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
        throw CancellationError()
    }

    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        nil
    }

    func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        []
    }

    func entry(id: Int64) async throws -> DictionaryEntry? {
        nil
    }

    func clearBundleCache() async {}
}

private func entry(
    id: Int64,
    hanji: String,
    romanization: String,
    definition: String
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
        senses: [
            DictionarySense(partOfSpeech: "名詞", definition: definition),
        ]
    )
}
