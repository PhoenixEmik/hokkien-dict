#if canImport(XCTest)
import XCTest

final class LanguageSwitchingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLanguagePickerSwitchesVisibleTabLabel() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_APP_LANGUAGE"] = "en"
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 30))
        settingsTab.tap()

        let languagePicker = app.descendants(matching: .any)["settings.interfaceLanguagePicker"]
        XCTAssertTrue(languagePicker.waitForExistence(timeout: 10))
        languagePicker.tap()

        let simplifiedChineseOption = app.descendants(matching: .any)["settings.interfaceLanguage.zh-Hans"]
        XCTAssertTrue(simplifiedChineseOption.waitForExistence(timeout: 10))
        simplifiedChineseOption.tap()

        let simplifiedSettingsTab = app.tabBars.buttons["设置"]
        XCTAssertTrue(simplifiedSettingsTab.waitForExistence(timeout: 10))
    }
}
#endif