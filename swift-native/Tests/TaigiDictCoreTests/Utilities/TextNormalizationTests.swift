import XCTest
@testable import TaigiDictCore

final class TextNormalizationTests: XCTestCase {
    func testNormalizeQueryFoldsTonesPunctuationAndSeparators() {
        XCTAssertEqual(
            TextNormalization.normalizeQuery("  Tsìt4-tsi̍t8/【狗】  "),
            "tsit tsit 狗"
        )
        XCTAssertEqual(
            TextNormalization.normalizeQuery("母仔（bó-á）, foo_bar"),
            "母仔 bo a foo bar"
        )
        XCTAssertEqual(TextNormalization.normalizeQuery("o\u{0358} \u{207F} óo"), "o n oo")
    }
}
