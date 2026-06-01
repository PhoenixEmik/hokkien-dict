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

    func testSQLiteRepositoryPrefersDisplayableExactMatchOverEmptyDuplicate() async throws {
        let databaseURL = try makeDatabaseURL()
        try buildDatabase(at: databaseURL, entriesData: duplicateLinkedEntriesData(), entryCount: 3, senseCount: 2, exampleCount: 0)

        let repository = SQLiteDictionaryRepository(databaseURL: databaseURL)

        let exactMatch = try await repository.findLinkedEntry("白")

        XCTAssertEqual(exactMatch?.id, 2)
    }

    func testSQLiteRepositoryKeepsExamplesAttachedToTheirOriginalSenses() async throws {
        let databaseURL = try makeDatabaseURL()
        try buildDatabase(
            at: databaseURL,
            entriesData: multiSenseExamplesData(),
            entryCount: 1,
            senseCount: 3,
            exampleCount: 3
        )

        let repository = SQLiteDictionaryRepository(databaseURL: databaseURL)
        let fetchedEntry = try await repository.entry(id: 13522)
        let entry = try XCTUnwrap(fetchedEntry)

        XCTAssertEqual(entry.senses.count, 3)
        XCTAssertEqual(entry.senses[0].definition, "遊玩。")
        XCTAssertEqual(entry.senses[0].examples.map(\.hanji), ["你明仔載欲佮阮去𨑨迌無？"])
        XCTAssertEqual(entry.senses[1].definition, "玩弄。")
        XCTAssertEqual(entry.senses[1].examples.map(\.hanji), ["你對伊的感情是認真的抑是𨑨迌爾爾？"])
        XCTAssertEqual(entry.senses[2].definition, "好玩的。")
        XCTAssertEqual(entry.senses[2].examples.map(\.hanji), ["食𨑨迌"])
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

    private func duplicateLinkedEntriesData() -> Data {
        Data(
            """
            {"id":1,"type":"","hanji":"白","romanization":"pe̍h","category":"","audio":"","hokkienSearch":"白 peh","mandarinSearch":"","senses":[]}
            {"id":2,"type":"","hanji":"白","romanization":"pe̍h","category":"","audio":"","hokkienSearch":"白 peh","mandarinSearch":"白色","senses":[{"partOfSpeech":"","definition":"白色","examples":[]}]}
            {"id":3,"type":"","hanji":"烏","romanization":"oo","category":"","audio":"","hokkienSearch":"烏 oo","mandarinSearch":"黑色","senses":[{"partOfSpeech":"","definition":"黑色","examples":[]}]}
            """.utf8
        )
    }

    private func multiSenseExamplesData() -> Data {
        Data(
            """
            {"id":13522,"type":"主詞目","hanji":"𨑨迌","romanization":"tshit-thô","category":"氣質態度,休閒、娛樂","audio":"13522(1)","hokkienSearch":"𨑨迌 tshit tho","mandarinSearch":"遊玩 玩弄 好玩的","senses":[{"partOfSpeech":"動詞","definition":"遊玩。","examples":[{"hanji":"你明仔載欲佮阮去𨑨迌無？","romanization":"Lí bîn-á-tsài beh kah guán khì tshit-thô--bô?","mandarin":"你明天要和我們去玩嗎？","audio":"13522-1-1"}]},{"partOfSpeech":"動詞","definition":"玩弄。","examples":[{"hanji":"你對伊的感情是認真的抑是𨑨迌爾爾？","romanization":"Lí tuì i ê kám-tsîng sī jīn-tsin--ê ia̍h-sī tshit-thô niā-niā?","mandarin":"你對他的感情是認真還是玩玩而已？","audio":"13522-2-1"}]},{"partOfSpeech":"形容詞","definition":"好玩的。","examples":[{"hanji":"食𨑨迌","romanization":"tsia̍h tshit-thô","mandarin":"吃著好玩","audio":"13522-3-1"}]}]}
            """.utf8
        )
    }
}
