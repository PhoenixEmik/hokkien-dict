import SwiftUI
import XCTest
@testable import TaigiDictUI

final class DictionarySearchPresentationTests: XCTestCase {
    func testRegularWidthUsesSplitPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: .regular,
                prefersDesktopSplit: false
            ),
            .regularSplit
        )
    }

    func testCompactWidthUsesStackPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: .compact,
                prefersDesktopSplit: false
            ),
            .compactStack
        )
    }

    func testUnknownWidthFallsBackToStackPresentation() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopSplit: false
            ),
            .compactStack
        )
    }

    func testMacOSPrefersSplitPresentationWithoutSizeClass() {
        XCTAssertEqual(
            DictionarySearchPresentation.resolve(
                horizontalSizeClass: nil,
                prefersDesktopSplit: true
            ),
            .regularSplit
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
