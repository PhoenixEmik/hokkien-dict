import XCTest
@testable import TaigiDictCore

final class OpenCCInputGuardTests: XCTestCase {
    func testRomanizationOnlyTextDoesNotNeedConversion() {
        XCTAssertFalse(OpenCCInputGuard.shouldConvert("su-tian"))
    }

    func testHanTextNeedsConversion() {
        XCTAssertTrue(OpenCCInputGuard.shouldConvert("辞典"))
    }

    func testEmptyTextDoesNotNeedConversion() {
        XCTAssertFalse(OpenCCInputGuard.shouldConvert(""))
    }
}
