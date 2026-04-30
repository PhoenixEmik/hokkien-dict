import XCTest
@testable import TaigiDictCore

final class DictionarySearchServiceTests: XCTestCase {
    func testSearchRanksExactHeadwordsBeforeLongerAndDefinitionMatches() {
        let index = DictionarySearchService.buildSearchIndex(entries: [
            entry(id: 10, hanji: "人民族", romanization: "jin-bin-tso\u{030D}k", definition: "民族"),
            entry(id: 20, hanji: "人民", romanization: "jin-bin", definition: "人民"),
            entry(id: 30, hanji: "政權", romanization: "tsing-khuan", definition: "人民的權力"),
            entry(id: 40, hanji: "新人民", romanization: "sin-jin-bin", definition: "新人民"),
        ])

        XCTAssertEqual(
            DictionarySearchService.searchEntryIDs(index: index, query: "人民"),
            [20, 10, 40, 30]
        )
    }

    func testInMemoryLinkedLookupPrefersExactVariantThenRomanization() async {
        let bundle = DictionaryBundle(
            entryCount: 3,
            senseCount: 3,
            exampleCount: 0,
            entries: [
                entry(id: 1, hanji: "母", romanization: "bo", definition: "母親"),
                entry(id: 2, hanji: "無", romanization: "bo", definition: "沒有", variantChars: ["毋"]),
                entry(id: 3, hanji: "母仔", romanization: "bo-a", definition: "雌性"),
            ]
        )
        let repository = InMemoryDictionaryRepository(bundle: bundle)

        let variantMatch = await repository.findLinkedEntry("毋")
        let romanizationMatch = await repository.findLinkedEntry("bo")
        let exactMatch = await repository.findLinkedEntry("母仔")
        let missingMatch = await repository.findLinkedEntry("母親")

        XCTAssertEqual(variantMatch?.id, 2)
        XCTAssertEqual(romanizationMatch?.id, 1)
        XCTAssertEqual(exactMatch?.id, 3)
        XCTAssertNil(missingMatch)
    }

    func testEntriesByIdsPreservesUniqueRequestedOrder() async {
        let bundle = DictionaryBundle(
            entryCount: 3,
            senseCount: 3,
            exampleCount: 0,
            entries: [
                entry(id: 1, hanji: "一", romanization: "tsi\u{030D}t", definition: "數字一"),
                entry(id: 2, hanji: "狗", romanization: "kau", definition: "狗"),
                entry(id: 3, hanji: "貓", romanization: "niau", definition: "貓"),
            ]
        )
        let repository = InMemoryDictionaryRepository(bundle: bundle)

        let results = await repository.entries(ids: [3, 1, 3, 99, 2])

        XCTAssertEqual(results.map(\.id), [3, 1, 2])
    }

    func testSearchMatchesMandarinAndExampleText() {
        let index = DictionarySearchService.buildSearchIndex(entries: [
            DictionaryEntry(
                id: 1,
                type: "",
                hanji: "船",
                romanization: "tsûn",
                category: "",
                audioID: "",
                hokkienSearch: "船 tsun",
                mandarinSearch: "海上的交通工具",
                senses: [
                    DictionarySense(
                        partOfSpeech: "",
                        definition: "航行的工具。",
                        examples: [
                            DictionaryExample(
                                hanji: "這本工具冊有寫著船的用法。",
                                romanization: "Tsit pún kang-kū-tshik ū siá tio̍h tsûn ê iōng-huat.",
                                mandarin: "這本工具冊有寫到船的用法。",
                                audioID: ""
                            )
                        ]
                    )
                ]
            )
        ])

        XCTAssertEqual(DictionarySearchService.searchEntryIDs(index: index, query: "交通工具"), [1])
        XCTAssertEqual(DictionarySearchService.searchEntryIDs(index: index, query: "工具冊"), [1])
    }
}

private func entry(
    id: Int64,
    hanji: String,
    romanization: String,
    definition: String,
    variantChars: [String] = []
) -> DictionaryEntry {
    DictionaryEntry(
        id: id,
        type: "",
        hanji: hanji,
        romanization: romanization,
        category: "",
        audioID: "",
        hokkienSearch: "\(hanji) \(romanization)",
        mandarinSearch: definition,
        variantChars: variantChars,
        senses: [
            DictionarySense(partOfSpeech: "", definition: definition),
        ]
    )
}
