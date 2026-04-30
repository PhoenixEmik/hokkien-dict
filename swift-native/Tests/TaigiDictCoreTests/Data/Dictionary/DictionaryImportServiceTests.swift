import Foundation
import XCTest
@testable import TaigiDictCore

final class DictionaryImportServiceTests: XCTestCase {
    func testDictionaryEntryDecodingTrimsOptionalStringLists() throws {
        let data = Data(
            """
            {
              "id": 42,
              "type": "名詞",
              "hanji": "網路",
              "romanization": "bang-loo",
              "category": "",
              "audio": "42",
              "hokkienSearch": "網路 bang-loo",
              "mandarinSearch": "網路",
              "variantChars": ["  网路", null, "", "網路  "],
              "wordSynonyms": [" 網际网络 ", ""],
              "wordAntonyms": ["   "],
              "alternativePronunciations": [" bang-lo "],
              "contractedPronunciations": [123],
              "colloquialPronunciations": [""],
              "phoneticDifferences": ["文讀"],
              "vocabularyComparisons": ["A/B"],
              "senses": [
                {"partOfSpeech": "", "definition": "資料傳輸系統", "examples": []}
              ]
            }
            """.utf8
        )

        let entry = try JSONDecoder().decode(DictionaryEntry.self, from: data)

        XCTAssertEqual(entry.variantChars, ["网路", "網路"])
        XCTAssertEqual(entry.wordSynonyms, ["網际网络"])
        XCTAssertTrue(entry.wordAntonyms.isEmpty)
        XCTAssertEqual(entry.alternativePronunciations, ["bang-lo"])
        XCTAssertEqual(entry.contractedPronunciations, ["123"])
        XCTAssertTrue(entry.colloquialPronunciations.isEmpty)
        XCTAssertEqual(entry.phoneticDifferences, ["文讀"])
        XCTAssertEqual(entry.vocabularyComparisons, ["A/B"])
    }

    func testImportBundleReadsJSONLAndValidatesCounts() throws {
        let manifest = DictionaryManifest(
            schemaVersion: 1,
            builtAt: "2026-04-30T00:00:00Z",
            entryCount: 2,
            senseCount: 2,
            exampleCount: 1
        )
        let jsonl = """
        {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"一種工具書。","examples":[{"hanji":"辭典是真重要的工具冊。","romanization":"Sû-tián sī tsin tiōng-iàu ê kang-kū-tsheh.","mandarin":"辭典是很重要的工具書。","audio":"ex-1"}]}]}
        {"id":2,"type":"名詞","hanji":"字典","romanization":"jī-tián","category":"","audio":"","hokkienSearch":"字典 ji tian","mandarinSearch":"字典","aliasTargetEntryId":1,"senses":[{"partOfSpeech":"","definition":"","examples":[]}]}
        """

        let bundle = try DictionaryImportService().importBundle(
            manifest: manifest,
            entriesData: Data(jsonl.utf8)
        )

        XCTAssertEqual(bundle.entryCount, 2)
        XCTAssertEqual(bundle.senseCount, 2)
        XCTAssertEqual(bundle.exampleCount, 1)
        XCTAssertEqual(bundle.entries.first?.audioID, "su-tian")
        XCTAssertEqual(bundle.entries.first?.senses.first?.examples.first?.audioID, "ex-1")
        XCTAssertEqual(bundle.entries.last?.aliasTargetEntryID, 1)
    }

    func testImportBundleRejectsMismatchedCounts() {
        let manifest = DictionaryManifest(
            schemaVersion: 1,
            builtAt: "2026-04-30T00:00:00Z",
            entryCount: 2,
            senseCount: 0,
            exampleCount: 0
        )
        let jsonl = #"{"id":1,"senses":[]}"#

        XCTAssertThrowsError(
            try DictionaryImportService().importBundle(
                manifest: manifest,
                entriesData: Data(jsonl.utf8)
            )
        ) { error in
            XCTAssertEqual(
                error as? DictionaryImportError,
                .entryCountMismatch(expected: 2, actual: 1)
            )
        }
    }

    func testImportDatabaseStreamsAndWritesLargeDataset() throws {
        let entryCount = 450
        let manifest = DictionaryManifest(
            schemaVersion: 1,
            builtAt: "2026-04-30T00:00:00Z",
            sourceModifiedAt: "2026-04-29T00:00:00Z",
            entryCount: entryCount,
            senseCount: entryCount,
            exampleCount: 0
        )
        let entries = (1...entryCount).map { index in
            """
            {"id":\(index),"type":"名詞","hanji":"詞\(index)","romanization":"su\(index)","category":"","audio":"","hokkienSearch":"詞\(index) su\(index)","mandarinSearch":"詞條\(index)","senses":[{"partOfSpeech":"","definition":"第\(index)筆","examples":[]}]}
            """
        }.joined(separator: "\n")

        let databaseURL = try makeDatabaseURL()
        let bundle = try DictionaryImportService().importDatabase(
            manifest: manifest,
            entriesData: Data(entries.utf8),
            databaseURL: databaseURL
        )

        XCTAssertEqual(bundle.entryCount, entryCount)
        XCTAssertEqual(bundle.senseCount, entryCount)
        XCTAssertEqual(bundle.exampleCount, 0)
        XCTAssertTrue(bundle.entries.isEmpty)
        XCTAssertEqual(bundle.databasePath, databaseURL.path)
    }

    func testImportDatabaseReportsProgressFromStartToEnd() throws {
        let entryCount = 8
        let manifest = DictionaryManifest(
            schemaVersion: 1,
            builtAt: "2026-04-30T00:00:00Z",
            entryCount: entryCount,
            senseCount: entryCount,
            exampleCount: 0
        )
        let entries = (1...entryCount).map { index in
            """
            {"id":\(index),"type":"名詞","hanji":"詞\(index)","romanization":"su\(index)","category":"","audio":"","hokkienSearch":"詞\(index) su\(index)","mandarinSearch":"詞條\(index)","senses":[{"partOfSpeech":"","definition":"第\(index)筆","examples":[]}]}
            """
        }.joined(separator: "\n")

        var updates: [DictionaryImportProgress] = []
        let databaseURL = try makeDatabaseURL()

        _ = try DictionaryImportService().importDatabase(
            manifest: manifest,
            entriesData: Data(entries.utf8),
            databaseURL: databaseURL,
            onProgress: { updates.append($0) }
        )

        XCTAssertFalse(updates.isEmpty)
        XCTAssertEqual(updates.first?.processedEntries, 0)
        XCTAssertEqual(updates.first?.totalEntries, entryCount)
        XCTAssertEqual(updates.last?.processedEntries, entryCount)
        XCTAssertEqual(updates.last?.totalEntries, entryCount)
        XCTAssertEqual(updates.last?.fraction, 1)
    }

    private func makeDatabaseURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("dictionary.sqlite")
    }
}
