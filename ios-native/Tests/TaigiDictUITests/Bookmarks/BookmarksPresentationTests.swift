import XCTest
@testable import TaigiDictUI

final class BookmarksPresentationTests: XCTestCase {
    func testMacOSUsesSplitPresentationWithoutSelection() {
        XCTAssertEqual(
            BookmarksPresentation.resolve(
                hasSelection: false,
                prefersDesktopLayout: true
            ),
            .desktopResultsSplit
        )
    }

    func testMacOSUsesSplitPresentationAfterSelection() {
        XCTAssertEqual(
            BookmarksPresentation.resolve(
                hasSelection: true,
                prefersDesktopLayout: true
            ),
            .desktopResultsSplit
        )
    }

    func testNonDesktopFallsBackToSinglePane() {
        XCTAssertEqual(
            BookmarksPresentation.resolve(
                hasSelection: true,
                prefersDesktopLayout: false
            ),
            .desktopSinglePane
        )
    }
}
