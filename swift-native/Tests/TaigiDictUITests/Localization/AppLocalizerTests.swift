import XCTest
import TaigiDictCore
@testable import TaigiDictUI

final class AppLocalizerTests: XCTestCase {
    func testReadsLocalizedStringsFromResourceCatalog() {
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .english), "Settings")
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .traditionalChinese), "設定")
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .simplifiedChinese), "设置")

        XCTAssertEqual(AppLocalizer.text(.bookmarksTitle, locale: .english), "Bookmarks")
        XCTAssertEqual(AppLocalizer.text(.bookmarksTitle, locale: .traditionalChinese), "書籤")
        XCTAssertEqual(AppLocalizer.text(.bookmarksTitle, locale: .simplifiedChinese), "书签")
    }

    func testAppLocaleResolvesFoundationNormalizedChineseIdentifiers() {
        XCTAssertEqual(AppLocalizer.appLocale(from: Locale(identifier: "zh-CN")), .simplifiedChinese)
        XCTAssertEqual(AppLocalizer.appLocale(from: Locale(identifier: "zh_CN")), .simplifiedChinese)
        XCTAssertEqual(AppLocalizer.appLocale(from: Locale(identifier: "zh-Hans")), .simplifiedChinese)
        XCTAssertEqual(AppLocalizer.appLocale(from: Locale(identifier: "zh-TW")), .traditionalChinese)
        XCTAssertEqual(AppLocalizer.appLocale(from: Locale(identifier: "en")), .english)
    }
}
