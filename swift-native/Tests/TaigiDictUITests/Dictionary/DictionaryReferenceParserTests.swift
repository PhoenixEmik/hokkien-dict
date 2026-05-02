import XCTest
@testable import TaigiDictUI

final class DictionaryReferenceParserTests: XCTestCase {
    func testSegmentsParsesBracketedDictionaryReferences() {
        XCTAssertEqual(
            DictionaryReferenceParser.segments(from: "參見【辭典】佮【字典】。"),
            [
                .text("參見"),
                .reference("辭典"),
                .text("佮"),
                .reference("字典"),
                .text("。"),
            ]
        )
    }

    func testSegmentsLeavesPlainTextUntouched() {
        XCTAssertEqual(
            DictionaryReferenceParser.segments(from: "無參照。"),
            [.text("無參照。")]
        )
    }
}
