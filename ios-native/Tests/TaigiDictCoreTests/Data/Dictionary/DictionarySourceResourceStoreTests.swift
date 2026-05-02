import Foundation
import XCTest
@testable import TaigiDictCore

final class DictionarySourceResourceStoreTests: XCTestCase {
    func testRestoreBundledSourceCopiesPackageToLocalDirectory() async throws {
        let bundledDirectory = try makeTemporaryDirectory()
        let localDirectory = try makeTemporaryDirectory().appendingPathComponent("DictionarySource", isDirectory: true)
        try writePackage(to: bundledDirectory)
        let store = DictionarySourceResourceStore(
            bundledDirectory: bundledDirectory,
            localDirectory: localDirectory
        )

        await store.restoreBundledSource()
        let snapshot = await store.snapshot()

        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: localDirectory.appendingPathComponent("dictionary_manifest.json").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: localDirectory.appendingPathComponent("dictionary_entries.jsonl").path
            )
        )
    }

    private func writePackage(to directory: URL) throws {
        let entriesData = Data("""
        {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"1","hokkienSearch":"辭典 sû-tián","mandarinSearch":"工具書","senses":[{"partOfSpeech":"名詞","definition":"工具書","examples":[]}]}
        """.utf8)
        try entriesData.write(to: directory.appendingPathComponent("dictionary_entries.jsonl"))
        try """
        {
          "schemaVersion": 1,
          "builtAt": "2026-04-30T00:00:00Z",
          "entryCount": 1,
          "senseCount": 1,
          "exampleCount": 0,
          "entriesFileName": "dictionary_entries.jsonl"
        }
        """.write(
            to: directory.appendingPathComponent("dictionary_manifest.json"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
