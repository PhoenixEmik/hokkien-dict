import SwiftUI
import XCTest
@testable import TaigiDictUI

final class DictionarySearchPresentationTests: XCTestCase {
    func testRegularWidthUsesSplitPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: .regular,
                prefersDesktopLayout: false
            ),
            .regularSplit
        )
    }

    func testCompactWidthUsesStackPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: .compact,
                prefersDesktopLayout: false
            ),
            .compactStack
        )
    }

    func testUnknownWidthFallsBackToStackPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopLayout: false
            ),
            .compactStack
        )
    }

    func testMacOSPrefersSinglePanePresentationWithoutQueryResults() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopLayout: true,
                isSearching: false,
                hasResults: false
            ),
            .desktopSinglePane
        )
    }

    func testMacOSUsesSplitPresentationWhileSearching() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopLayout: true,
                isSearching: true,
                hasResults: false
            ),
            .desktopResultsSplit
        )
    }

    func testMacOSUsesSplitPresentationWhenResultsExist() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopLayout: true,
                isSearching: false,
                hasResults: true
            ),
            .desktopResultsSplit
        )
    }

    func testHistoryOnlyStartPresentationSuppressesStartContent() {
        XCTAssertFalse(DictionarySearchStartPresentation.historyOnly.showsStartContent)
    }

    func testRegularDetailTitleUsesDictionaryTitleBeforeSelection() {
        XCTAssertEqual(
            DictionarySearchNavigationTitle.detailTitle(
                selectedEntryHanji: nil,
                dictionaryTitle: "辭典"
            ),
            "辭典"
        )
    }

    func testRegularDetailTitleKeepsDictionaryTitleAfterSelection() {
        XCTAssertEqual(
            DictionarySearchNavigationTitle.detailTitle(
                selectedEntryHanji: "伴手",
                dictionaryTitle: "辭典"
            ),
            "辭典"
        )
    }
}
