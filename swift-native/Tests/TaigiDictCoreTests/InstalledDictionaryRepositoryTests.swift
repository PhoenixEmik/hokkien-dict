import CryptoKit
import Foundation
import XCTest
@testable import TaigiDictCore

final class InstalledDictionaryRepositoryTests: XCTestCase {
    func testInstalledRepositoryReportsLocalMaintenanceSupport() async {
        let sourceDirectory = try! makeTemporaryDirectory()
        let installedDirectory = try! makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)
        try! writePackage(to: sourceDirectory)

        let repository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )

        let supportsMaintenance = await repository.supportsLocalMaintenance()
        XCTAssertTrue(supportsMaintenance)
    }

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

    func testRebuildInstalledDatabaseReimportsUpdatedSourcePackage() async throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let installedDirectory = try makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)

        try writePackage(
            to: sourceDirectory,
            entries: [
                TestEntry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "一種工具書。"),
            ]
        )

        let repository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )
        _ = try await repository.search("辭典", limit: 5, offset: 0)

        try writePackage(
            to: sourceDirectory,
            entries: [
                TestEntry(id: 2, hanji: "語詞", romanization: "gí-sû", definition: "詞語。"),
            ]
        )

        try await repository.rebuildInstalledDatabase()
        let rebuiltResults = try await repository.search("語詞", limit: 5, offset: 0)

        XCTAssertEqual(rebuiltResults.map(\.hanji), ["語詞"])
    }

    func testClearInstalledDatabaseRemovesInstalledArtifacts() async throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let installedDirectory = try makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)
        try writePackage(to: sourceDirectory)

        let repository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )
        _ = try await repository.loadBundle()

        try await repository.clearInstalledDatabase()

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: installedDirectory.appendingPathComponent("dictionary.sqlite").path
            )
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: installedDirectory.appendingPathComponent("dictionary_manifest.json").path
            )
        )
    }

    func testSearchFailsAfterClearWhenSourceIsMissing() async throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let installedDirectory = try makeTemporaryDirectory().appendingPathComponent("Installed", isDirectory: true)
        try writePackage(to: sourceDirectory)

        let repository = InstalledDictionaryRepository(
            sourceDirectory: sourceDirectory,
            installedDirectory: installedDirectory
        )
        _ = try await repository.loadBundle()
        try await repository.clearInstalledDatabase()
        try FileManager.default.removeItem(at: sourceDirectory)

        do {
            _ = try await repository.search("辭典", limit: 5, offset: 0)
            XCTFail("Expected search to fail when both source and installed package are missing")
        } catch {
            guard case DictionaryPackageLoaderError.missingManifest = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    private func writePackage(to directory: URL, entries: [TestEntry] = [
        TestEntry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "一種工具書。"),
    ]) throws {
        let jsonl = entries.map { entry in
            """
            {"id":\(entry.id),"type":"名詞","hanji":"\(entry.hanji)","romanization":"\(entry.romanization)","category":"主詞目","audio":"\(entry.id)","hokkienSearch":"\(entry.hanji) \(entry.romanization)","mandarinSearch":"\(entry.definition)","senses":[{"partOfSpeech":"名詞","definition":"\(entry.definition)","examples":[]}]}
            """
        }.joined(separator: "\n")

        let entriesData = Data(jsonl.utf8)
        try entriesData.write(to: directory.appendingPathComponent("dictionary_entries.jsonl"))
        try manifestJSON(
            checksum: SHA256.hash(data: entriesData).hexString,
            entryCount: entries.count,
            senseCount: entries.count,
            exampleCount: 0
        ).write(
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

    private func manifestJSON(
        checksum: String,
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int
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

private struct TestEntry {
    var id: Int
    var hanji: String
    var romanization: String
    var definition: String
}

private extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}