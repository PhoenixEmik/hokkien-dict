import XCTest
import TaigiDictCore
@testable import TaigiDictUI

final class AppLocalizerTests: XCTestCase {
    func testExplicitAppLanguageOverridesSystemLocale() {
        XCTAssertEqual(
            AppLocalizer.text(
                .settingsTitle,
                language: .en,
                systemLocale: Locale(identifier: "zh-Hant")
            ),
            "Settings"
        )
        XCTAssertEqual(
            AppLocalizer.text(
                .settingsTitle,
                language: .zhHans,
                systemLocale: Locale(identifier: "en")
            ),
            "设置"
        )
    }

    func testReadsLocalizedStringsFromResourceCatalog() {
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .english), "Settings")
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .traditionalChinese), "設定")
        XCTAssertEqual(AppLocalizer.text(.settingsTitle, locale: .simplifiedChinese), "设置")

        XCTAssertEqual(AppLocalizer.text(.localeSystem, locale: .english), "System")
        XCTAssertEqual(AppLocalizer.text(.themeSystem, locale: .english), "System")

        XCTAssertEqual(AppLocalizer.text(.aboutVersionValue, locale: .english), "1.2.0")
        XCTAssertEqual(AppLocalizer.text(.aboutVersionValue, locale: .traditionalChinese), "1.2.0")
        XCTAssertEqual(AppLocalizer.text(.aboutVersionValue, locale: .simplifiedChinese), "1.2.0")
        XCTAssertEqual(AppLocalizer.text(.aboutGitHub, locale: .traditionalChinese), "開放源碼")

        XCTAssertEqual(AppLocalizer.text(.licenseAppCodeDescription, locale: .english), "MIT License")
        XCTAssertEqual(AppLocalizer.text(.licenseMinistryCopyright, locale: .traditionalChinese), "教育部著作權說明")
        XCTAssertEqual(
            AppLocalizer.text(.licenseThirdParty, locale: .traditionalChinese),
            "套件授權"
        )

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

    func testAppLocaleResolvesStoredSettingsLocaleIdentifiers() {
        for locale in AppLocale.allCases {
            XCTAssertEqual(
                AppLocalizer.appLocale(from: Locale(identifier: locale.rawValue)),
                locale
            )
        }
    }

    func testFormatsLocalizedStringsFromResourceCatalog() {
        XCTAssertEqual(
            AppLocalizer.formattedText(.detailLinkedReferenceFormat, locale: .traditionalChinese, "詞目"),
            "【詞目】"
        )
        XCTAssertEqual(
            AppLocalizer.formattedText(.detailLinkedReferenceFormat, locale: .english, "entry"),
            "[entry]"
        )
        XCTAssertEqual(
            AppLocalizer.formattedText(.settingsReadingTextScaleValueFormat, locale: .english, 1.25),
            "1.25x"
        )
    }

    func testAllLocalizedKeysResolveFromResourceCatalog() {
        for key in AppLocalizedStringKey.allCases {
            for locale in AppLocale.allCases {
                XCTAssertNotEqual(
                    AppLocalizer.text(key, locale: locale),
                    key.rawValue,
                    "\(key.rawValue) is missing for \(locale.rawValue)"
                )
            }
        }
    }
}
