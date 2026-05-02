import XCTest
@testable import TaigiDictCore

final class DictionaryEntryTests: XCTestCase {
    func testBriefSummaryUsesFirstSenseDefinition() {
        let entry = DictionaryEntry(
            id: 1,
            type: "名詞",
            hanji: "辭典",
            romanization: "sû-tián",
            category: "主詞目",
            audioID: "su-tian",
            hokkienSearch: "辭典 su tian",
            mandarinSearch: "辭典",
            senses: [
                DictionarySense(partOfSpeech: "名詞", definition: "一種工具書。"),
            ]
        )

        XCTAssertEqual(entry.briefSummary, "一種工具書。")
    }

    func testAliasEntryHasEmptyBriefSummary() {
        let entry = DictionaryEntry(
            id: 2,
            type: "",
            hanji: "字典",
            romanization: "jī-tián",
            category: "",
            audioID: "",
            hokkienSearch: "",
            mandarinSearch: "",
            aliasTargetEntryID: 1
        )

        XCTAssertTrue(entry.briefSummary.isEmpty)
    }
}
