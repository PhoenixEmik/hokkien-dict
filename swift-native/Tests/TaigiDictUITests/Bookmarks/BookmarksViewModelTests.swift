import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class BookmarksViewModelTests: XCTestCase {
    func testLoadResolvesBookmarkedEntriesInStoredOrder() async {
        let entries = [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
            entry(id: 2, hanji: "字典", romanization: "jī-tián", definition: "工具書"),
        ]
        let repository = InMemoryRepository(entries: entries)
        let bookmarkStore = InMemoryBookmarksStore(ids: [2, 1])
        let viewModel = BookmarksViewModel(
            library: DictionaryLibrary(repository: repository),
            bookmarkStore: bookmarkStore
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.entries.map(\.id), [2, 1])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRemoveBookmarksDeletesFromStoreAndReloads() async {
        let entries = [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
            entry(id: 2, hanji: "字典", romanization: "jī-tián", definition: "工具書"),
        ]
        let repository = InMemoryRepository(entries: entries)
        let bookmarkStore = InMemoryBookmarksStore(ids: [2, 1])
        let viewModel = BookmarksViewModel(
            library: DictionaryLibrary(repository: repository),
            bookmarkStore: bookmarkStore
        )

        await viewModel.load()
        await viewModel.removeBookmarks(at: IndexSet(integer: 0))

        XCTAssertEqual(viewModel.entries.map(\.id), [1])
        let ids = await bookmarkStore.bookmarkedEntryIDs()
        XCTAssertEqual(ids, [1])
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

private actor InMemoryBookmarksStore: BookmarksStoreProtocol {
    private var ids: [Int64]

    init(ids: [Int64]) {
        self.ids = ids
    }

    func bookmarkedEntryIDs() async -> [Int64] {
        ids
    }

    func isBookmarked(_ entryID: Int64) async -> Bool {
        ids.contains(entryID)
    }

    @discardableResult
    func toggleBookmark(entryID: Int64) async -> Bool {
        if let index = ids.firstIndex(of: entryID) {
            ids.remove(at: index)
            return false
        }
        ids.insert(entryID, at: 0)
        return true
    }

    func removeBookmarks(entryIDs: [Int64]) async {
        let blocked = Set(entryIDs)
        ids.removeAll { blocked.contains($0) }
    }
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
