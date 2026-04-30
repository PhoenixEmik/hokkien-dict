import Foundation
import XCTest
@testable import TaigiDictCore

final class BookmarkStoreTests: XCTestCase {
    func testToggleBookmarkInsertsAtFrontAndRemovesDuplicates() async {
        let defaults = makeIsolatedDefaults()
        let store = BookmarkStore(userDefaults: defaults, storageKey: "bookmark_store_tests")

        _ = await store.toggleBookmark(entryID: 10)
        _ = await store.toggleBookmark(entryID: 20)
        _ = await store.toggleBookmark(entryID: 10)

        let ids = await store.bookmarkedEntryIDs()
        XCTAssertEqual(ids, [20])
    }

    func testRemoveBookmarksRemovesOnlySpecifiedIDs() async {
        let defaults = makeIsolatedDefaults()
        let store = BookmarkStore(userDefaults: defaults, storageKey: "bookmark_store_tests")

        _ = await store.toggleBookmark(entryID: 1)
        _ = await store.toggleBookmark(entryID: 2)
        _ = await store.toggleBookmark(entryID: 3)

        await store.removeBookmarks(entryIDs: [2, 99])

        let ids = await store.bookmarkedEntryIDs()
        XCTAssertEqual(ids, [3, 1])
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "BookmarkStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
