import Foundation
import XCTest
@testable import TaigiDictCore

final class PackageDictionaryRepositoryTests: XCTestCase {
    func testPackageRepositoryLoadsGeneratedPackageAndSearches() async throws {
        let repository = PackageDictionaryRepository(packageDirectory: try generatedDictionaryDirectory())

        let bundle = try await repository.loadBundle()
        let results = try await repository.search("辭典", limit: 5, offset: 0)

        XCTAssertEqual(bundle.entryCount, 29_593)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.hanji.contains("辭典") })
    }

    func testPackageRepositoryOffsetDropsEarlierResults() async throws {
        let repository = PackageDictionaryRepository(packageDirectory: try generatedDictionaryDirectory())

        let firstTwo = try await repository.search("一", limit: 2, offset: 0)
        let second = try await repository.search("一", limit: 1, offset: 1)

        XCTAssertEqual(second.map(\.id), Array(firstTwo.dropFirst().map(\.id)))
    }

    func testDictionaryLibraryPrepareSetsReadySummary() async throws {
        let repository = PackageDictionaryRepository(packageDirectory: try generatedDictionaryDirectory())
        let library = DictionaryLibrary(repository: repository)

        let phase = await library.prepare()

        XCTAssertEqual(
            phase,
            .ready(
                DictionaryLibrarySummary(
                    entryCount: 29_593,
                    senseCount: 23_298,
                    exampleCount: 17_907
                )
            )
        )
    }

    private func generatedDictionaryDirectory() throws -> URL {
        let packageRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let generatedDirectory = packageRoot.appendingPathComponent("Generated/Dictionary")
        let manifestURL = generatedDirectory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw XCTSkip("Generated dictionary package is not present.")
        }
        return generatedDirectory
    }
}
