import XCTest
@testable import TaigiDictUI

final class BookmarksSelectionTransitionTests: XCTestCase {
    func testSelectsNextEntryAfterDeletedRangeWhenAvailable() {
        let nextSelection = BookmarksSelectionTransition.nextSelection(
            orderedEntryIDs: [1, 2, 3, 4],
            removing: [2, 3]
        )

        XCTAssertEqual(nextSelection, 4)
    }

    func testFallsBackToPreviousEntryWhenDeletingLastRow() {
        let nextSelection = BookmarksSelectionTransition.nextSelection(
            orderedEntryIDs: [1, 2, 3],
            removing: [3]
        )

        XCTAssertEqual(nextSelection, 2)
    }

    func testReturnsNilWhenAllEntriesAreDeleted() {
        let nextSelection = BookmarksSelectionTransition.nextSelection(
            orderedEntryIDs: [1, 2],
            removing: [1, 2]
        )

        XCTAssertNil(nextSelection)
    }
}
