import CryptoKit
import Foundation
import XCTest
@testable import TaigiDictCore

final class InstalledDictionaryRepositoryTests: XCTestCase {
    func testInstalledRepositoryCopiesSourcePackageBeforeLoading() async throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let installedDirectory = try makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)
        try writePackage(to: sourceDirectory)

        let repository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )

        let bundle = try await repository.loadBundle()
        let results = try await repository.search("辭典", limit: 5, offset: 0)

        XCTAssertEqual(bundle.entryCount, 1)
        XCTAssertEqual(bundle.databasePath, installedDirectory.appendingPathComponent("dictionary.sqlite").path)
        XCTAssertEqual(results.map(\.hanji), ["辭典"])
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: installedDirectory.appendingPathComponent("dictionary.sqlite").path
            )
        )
    }

    func testInstalledRepositoryFallsBackToInstalledPackageAfterSourceRemoval() async throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let installedDirectory = try makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)
        try writePackage(to: sourceDirectory)

        let initialRepository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )
        _ = try await initialRepository.loadBundle()

        try FileManager.default.removeItem(at: sourceDirectory)

        let reloadedRepository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )
        let results = try await reloadedRepository.search("辭典", limit: 5, offset: 0)

        XCTAssertEqual(results.map(\.hanji), ["辭典"])
    }

    private func writePackage(to directory: URL) throws {
        let jsonl = """
        {"id":1,"type":"名詞","hanji":"辭典","romanization":"sû-tián","category":"主詞目","audio":"su-tian","hokkienSearch":"辭典 su tian","mandarinSearch":"辭典","senses":[{"partOfSpeech":"名詞","definition":"一種工具書。","examples":[]}]}
        """
        let entriesData = Data(jsonl.utf8)
        try entriesData.write(to: directory.appendingPathComponent("dictionary_entries.jsonl"))
        try manifestJSON(checksum: SHA256.hash(data: entriesData).hexString).write(
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

    private func manifestJSON(checksum: String) -> String {
        """
        {
          "schemaVersion": 1,
          "builtAt": "2026-04-30T00:00:00Z",
          "entryCount": 1,
          "senseCount": 1,
          "exampleCount": 0,
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