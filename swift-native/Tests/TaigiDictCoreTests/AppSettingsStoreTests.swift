import Foundation
import XCTest
@testable import TaigiDictCore

final class AppSettingsStoreTests: XCTestCase {
    func testSnapReadingTextScaleClampsAndRoundsToStep() {
        XCTAssertEqual(AppSettingsSnapshot.snapReadingTextScale(0.1), 0.9)
        XCTAssertEqual(AppSettingsSnapshot.snapReadingTextScale(10.0), 1.4)
        XCTAssertEqual(AppSettingsSnapshot.snapReadingTextScale(1.08), 1.1)
    }

    func testUserDefaultsStoreLoadAndSet() async {
        let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsAppSettingsStore(defaults: defaults)

        await store.setInterfaceLocale(.english)
        await store.setThemePreference(.dark)
        await store.setReadingTextScale(1.37)

        let snapshot = await store.load()
        XCTAssertEqual(snapshot.interfaceLocale, .english)
        XCTAssertEqual(snapshot.themePreference, .dark)
        XCTAssertEqual(snapshot.readingTextScale, 1.4)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
