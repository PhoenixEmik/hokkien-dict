import Foundation
import XCTest
@testable import TaigiDictCore

final class SQLiteDictionaryRepositoryTests: XCTestCase {
    func testSQLiteRepositoryLoadsSummaryAndSearchesWithStableRanking() async throws {
        let databaseURL = try makeDatabaseURL()
        try buildDatabase(at: databaseURL, entriesData: rankingEntriesData(), entryCount: 4, senseCount: 4, exampleCount: 1)

        let repository = SQLiteDictionaryRepository(databaseURL: databaseURL)
        let bundle = try await repository.loadBundle()
        let results = try await repository.search("人民", limit: 4, offset: 0)

        XCTAssertTrue(bundle.isDatabaseBacked)
        XCTAssertEqual(bundle.entryCount, 4)
        XCTAssertEqual(results.map(\.id), [20, 10, 40, 30])
    }

    func testSQLiteRepositoryResolvesLinkedEntriesAndPreservesRequestedOrder() async throws {
        let databaseURL = try makeDatabaseURL()
        try buildDatabase(at: databaseURL, entriesData: linkedEntriesData(), entryCount: 3, senseCount: 3, exampleCount: 0)

        let repository = SQLiteDictionaryRepository(databaseURL: databaseURL)

        let variantMatch = try await repository.findLinkedEntry("毋")
        let romanizationMatch = try await repository.findLinkedEntry("bo")
        let requestedEntries = try await repository.entries(ids: [3, 1, 3, 99, 2])

        XCTAssertEqual(variantMatch?.id, 2)
        XCTAssertEqual(romanizationMatch?.id, 1)
        XCTAssertEqual(requestedEntries.map(\.id), [3, 1, 2])
    }

    private func buildDatabase(
        at url: URL,
        entriesData: Data,
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int
    ) throws {
        let manifest = DictionaryManifest(
            schemaVersion: 1,
            builtAt: "2026-04-30T00:00:00Z",
            sourceModifiedAt: "2026-04-30T00:00:00Z",
            entryCount: entryCount,
            senseCount: senseCount,
            exampleCount: exampleCount
        )
        _ = try DictionaryImportService().importDatabase(
            manifest: manifest,
            entriesData: entriesData,
            databaseURL: url
        )
    }

    private func makeDatabaseURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("dictionary.sqlite")
    }

    private func rankingEntriesData() -> Data {
        Data(
            """
            {"id":10,"type":"","hanji":"人民族","romanization":"jin-bin-tso̍k","category":"","audio":"","hokkienSearch":"人民族 jin bin tsok","mandarinSearch":"民族","senses":[{"partOfSpeech":"","definition":"民族","examples":[]}]}
            {"id":20,"type":"","hanji":"人民","romanization":"jin-bin","category":"","audio":"","hokkienSearch":"人民 jin bin","mandarinSearch":"人民","senses":[{"partOfSpeech":"","definition":"人民","examples":[]}]}
            {"id":30,"type":"","hanji":"政權","romanization":"tsing-khuan","category":"","audio":"","hokkienSearch":"政權 tsing khuan","mandarinSearch":"政權","senses":[{"partOfSpeech":"","definition":"人民的權力","examples":[{"hanji":"人民做主。","romanization":"Jîn-bîn tsò-tsú.","mandarin":"人民作主。","audio":""}]}]}
            {"id":40,"type":"","hanji":"新人民","romanization":"sin-jin-bin","category":"","audio":"","hokkienSearch":"新人民 sin jin bin","mandarinSearch":"新人民","senses":[{"partOfSpeech":"","definition":"新人民","examples":[]}]}
            """.utf8
        )
    }

    private func linkedEntriesData() -> Data {
        Data(
            """
            {"id":1,"type":"","hanji":"母","romanization":"bo","category":"","audio":"","hokkienSearch":"母 bo","mandarinSearch":"母親","senses":[{"partOfSpeech":"","definition":"母親","examples":[]}]}
            {"id":2,"type":"","hanji":"無","romanization":"bo","category":"","audio":"","hokkienSearch":"無 bo","mandarinSearch":"沒有","variantChars":["毋"],"senses":[{"partOfSpeech":"","definition":"沒有","examples":[]}]}
            {"id":3,"type":"","hanji":"母仔","romanization":"bo-a","category":"","audio":"","hokkienSearch":"母仔 bo a","mandarinSearch":"雌性","senses":[{"partOfSpeech":"","definition":"雌性","examples":[]}]}
            """.utf8
        )
    }
}