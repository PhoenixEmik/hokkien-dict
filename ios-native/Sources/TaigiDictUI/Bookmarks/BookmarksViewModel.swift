import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class BookmarksViewModel {
    public private(set) var isLoading = false
    public private(set) var entries: [DictionaryEntry] = []
    public private(set) var errorMessage: String?
    public var detailEntry: DictionaryEntry?

    private let library: DictionaryLibrary
    private let bookmarkStore: any BookmarksStoreProtocol

    public init(library: DictionaryLibrary, bookmarkStore: any BookmarksStoreProtocol) {
        self.library = library
        self.bookmarkStore = bookmarkStore
    }

    public func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let bookmarkedIDs = await bookmarkStore.bookmarkedEntryIDs()
            entries = try await library.entries(ids: bookmarkedIDs)
        } catch {
            entries = []
            errorMessage = String(describing: error)
        }

        isLoading = false
    }

    public func removeBookmarks(at offsets: IndexSet) async {
        let ids: [Int64] = offsets.compactMap { index in
            guard entries.indices.contains(index) else {
                return nil
            }
            return entries[index].id
        }

        await bookmarkStore.removeBookmarks(entryIDs: ids)
        await load()
    }
}
