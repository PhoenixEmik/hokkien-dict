import XCTest
@testable import TaigiDictUI

final class AppLanguageManagerTests: XCTestCase {
    func testLoadsPersistedLanguageFromUserDefaults() {
        let defaults = makeDefaults(testName: #function)
        defaults.set(AppLanguage.zhHans.rawValue, forKey: AppLanguageManager.userDefaultsKey)

        let manager = AppLanguageManager(
            defaults: defaults,
            systemLocale: Locale(identifier: "en")
        )

        XCTAssertEqual(manager.selectedLanguage, .zhHans)
        XCTAssertEqual(manager.appLocale, .simplifiedChinese)
    }

    func testPersistsSelectedLanguageAndTracksSystemLocale() {
        let defaults = makeDefaults(testName: #function)
        let manager = AppLanguageManager(
            defaults: defaults,
            systemLocale: Locale(identifier: "zh-Hant")
        )

        manager.setLanguage(.en)

        XCTAssertEqual(defaults.string(forKey: AppLanguageManager.userDefaultsKey), AppLanguage.en.rawValue)
        XCTAssertEqual(manager.locale.identifier, "en")

        manager.setLanguage(.system)
        manager.updateSystemLocale(Locale(identifier: "zh-Hans"))

        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertEqual(manager.appLocale, .simplifiedChinese)
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let suiteName = "AppLanguageManagerTests.\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}