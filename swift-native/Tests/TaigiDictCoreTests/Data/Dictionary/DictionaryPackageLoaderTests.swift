import CryptoKit
import Foundation
import XCTest
@testable import TaigiDictCore

final class DictionaryPackageLoaderTests: XCTestCase {
    func testPackageLoaderValidatesChecksumAndImportsBundle() throws {
        let directory = try makeTemporaryDirectory()
        let jsonl = """
        {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"一種工具書。","examples":[]}]}
        """
        let entriesData = Data(jsonl.utf8)
        try entriesData.write(to: directory.appendingPathComponent("dictionary_entries.jsonl"))
        let manifest = manifestJSON(
            entryCount: 1,
            senseCount: 1,
            exampleCount: 0,
            checksum: SHA256.hash(data: entriesData).hexString
        )
        try manifest.write(to: directory.appendingPathComponent("dictionary_manifest.json"), atomically: true, encoding: .utf8)

        let bundle = try DictionaryPackageLoader().loadBundle(from: directory)

        XCTAssertEqual(bundle.entryCount, 1)
        XCTAssertEqual(bundle.entries.first?.hanji, "辭典")
    }

    func testPackageLoaderRejectsChecksumMismatch() throws {
        let directory = try makeTemporaryDirectory()
        try #"{"id":1,"senses":[]}"#.write(
            to: directory.appendingPathComponent("dictionary_entries.jsonl"),
            atomically: true,
            encoding: .utf8
        )
        let manifest = manifestJSON(entryCount: 1, senseCount: 0, exampleCount: 0, checksum: "bad")
        try manifest.write(to: directory.appendingPathComponent("dictionary_manifest.json"), atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try DictionaryPackageLoader().loadBundle(from: directory)) { error in
            guard case DictionaryPackageLoaderError.checksumMismatch = error else {
                XCTFail("Expected checksum mismatch, got \(error)")
                return
            }
        }
    }

    func testGeneratedDictionaryPackageLoadsWhenPresent() throws {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let generatedDirectory = packageRoot.appendingPathComponent("Generated/Dictionary")
        let manifestURL = generatedDirectory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw XCTSkip("Generated dictionary package is not present.")
        }

        let bundle = try DictionaryPackageLoader().loadBundle(from: generatedDirectory)

        XCTAssertEqual(bundle.entryCount, 28_965)
        XCTAssertEqual(bundle.senseCount, 23_106)
        XCTAssertEqual(bundle.exampleCount, 17_700)
        XCTAssertEqual(bundle.entries.first?.id, 1)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func manifestJSON(
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int,
        checksum: String
    ) -> String {
        """
        {
          "schemaVersion": 1,
          "builtAt": "2026-04-30T00:00:00Z",
          "entryCount": \(entryCount),
          "senseCount": \(senseCount),
          "exampleCount": \(exampleCount),
          "entriesFileName": "dictionary_entries.jsonl",
          "checksumSHA256": "\(checksum)"
        }
        """
    }
}

private extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
