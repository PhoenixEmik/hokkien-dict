import Foundation
import XCTest
@testable import TaigiDictUI

final class SettingsDateFormatterTests: XCTestCase {
    func testDisplayStringFormatsISO8601Value() {
        let formatter = SettingsDateFormatter(
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        let output = formatter.displayString(from: "2026-04-30T00:00:00Z")

        XCTAssertNotNil(output)
        XCTAssertNotEqual(output, "2026-04-30T00:00:00Z")
        XCTAssertTrue(output?.contains("2026") == true)
    }

    func testDisplayStringFormatsISO8601WithFractionalSeconds() {
        let formatter = SettingsDateFormatter(
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        let output = formatter.displayString(from: "2026-04-30T00:00:00.123Z")

        XCTAssertNotNil(output)
        XCTAssertTrue(output?.contains("2026") == true)
    }

    func testDisplayStringReturnsRawWhenDateIsInvalid() {
        let formatter = SettingsDateFormatter()

        let output = formatter.displayString(from: "not-a-date")

        XCTAssertEqual(output, "not-a-date")
    }

    func testDisplayStringReturnsNilWhenInputMissing() {
        let formatter = SettingsDateFormatter()

        XCTAssertNil(formatter.displayString(from: nil))
        XCTAssertNil(formatter.displayString(from: ""))
    }
}
