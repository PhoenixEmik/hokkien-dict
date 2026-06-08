#if canImport(XCTest)
import XCTest

final class LinkedTermNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCompactDetailAntonymNavigatesToLinkedEntry() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_APP_LANGUAGE"] = "zh-Hant"
        app.launch()

        let dictionaryTab = app.tabBars.buttons["辭典"]
        XCTAssertTrue(dictionaryTab.waitForExistence(timeout: 30))
        dictionaryTab.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("烏")

        let blackEntryButton = app.buttons["dictionary.entry.6227"]
        XCTAssertTrue(blackEntryButton.waitForExistence(timeout: 10))
        blackEntryButton.tap()

        let whiteRelationshipButton = app.buttons["dictionary.relationship.白"]
        XCTAssertTrue(whiteRelationshipButton.waitForExistence(timeout: 10))
        whiteRelationshipButton.tap()

        let whiteNavigationTitle = app.navigationBars.staticTexts["白"]
        XCTAssertTrue(whiteNavigationTitle.waitForExistence(timeout: 10))
    }
}
#endif
