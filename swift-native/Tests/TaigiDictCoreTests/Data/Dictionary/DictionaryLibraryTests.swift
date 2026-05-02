import XCTest
@testable import TaigiDictCore

final class DictionaryLibraryTests: XCTestCase {
    func testSupportsLocalMaintenanceReflectsRepositoryCapability() async {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true
        )
        let library = DictionaryLibrary(repository: repository)

        let supports = await library.supportsLocalMaintenance()

        XCTAssertTrue(supports)
    }

    func testRebuildInstalledDatabaseClearsCacheAndResetsPhase() async throws {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true
        )
        let library = DictionaryLibrary(repository: repository)
        _ = await library.prepare()

        try await library.rebuildInstalledDatabase()
        let phase = await library.phase
        let rebuildCount = await repository.rebuildCount
        let clearCacheCount = await repository.clearCacheCount

        XCTAssertEqual(phase, .idle)
        XCTAssertEqual(rebuildCount, 1)
        XCTAssertEqual(clearCacheCount, 1)
    }

    func testClearInstalledDatabaseClearsCacheAndResetsPhase() async throws {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true
        )
        let library = DictionaryLibrary(repository: repository)
        _ = await library.prepare()

        try await library.clearInstalledDatabase()
        let phase = await library.phase
        let clearInstalledCount = await repository.clearInstalledCount
        let clearCacheCount = await repository.clearCacheCount

        XCTAssertEqual(phase, .idle)
        XCTAssertEqual(clearInstalledCount, 1)
        XCTAssertEqual(clearCacheCount, 1)
    }

    func testCurrentSummaryReturnsPreparedSummary() async {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true
        )
        let library = DictionaryLibrary(repository: repository)
        let initialSummary = await library.currentSummary()

        XCTAssertNil(initialSummary)

        _ = await library.prepare()
        let summary = await library.currentSummary()

        XCTAssertEqual(summary, DictionaryLibrarySummary(entryCount: 1, senseCount: 1, exampleCount: 0))
    }

    func testMetadataMapsBuiltAtAndSourceModifiedAt() async throws {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true,
            metadata: [
                "built_at": "2026-04-30T00:00:00Z",
                "source_modified_at": "2026-04-29T00:00:00Z",
            ]
        )
        let library = DictionaryLibrary(repository: repository)

        let metadata = try await library.metadata()

        XCTAssertEqual(
            metadata,
            DictionaryLibraryMetadata(
                builtAt: "2026-04-30T00:00:00Z",
                sourceModifiedAt: "2026-04-29T00:00:00Z"
            )
        )
    }

    func testMetadataTreatsEmptySourceModifiedAtAsNil() async throws {
        let repository = LibraryMaintenanceRepository(
            bundle: sampleBundle(),
            supportsMaintenance: true,
            metadata: [
                "built_at": "2026-04-30T00:00:00Z",
                "source_modified_at": "",
            ]
        )
        let library = DictionaryLibrary(repository: repository)

        let metadata = try await library.metadata()

        XCTAssertEqual(
            metadata,
            DictionaryLibraryMetadata(
                builtAt: "2026-04-30T00:00:00Z",
                sourceModifiedAt: nil
            )
        )
    }

    private func sampleBundle() -> DictionaryBundle {
        DictionaryBundle(
            entryCount: 1,
            senseCount: 1,
            exampleCount: 0,
            entries: [
                DictionaryEntry(
                    id: 1,
                    type: "名詞",
                    hanji: "辭典",
                    romanization: "sû-tián",
                    category: "主詞目",
                    audioID: "",
                    hokkienSearch: "辭典 su tian",
                    mandarinSearch: "工具書",
                    senses: [
                        DictionarySense(partOfSpeech: "名詞", definition: "工具書")
                    ]
                )
            ]
        )
    }
}

private actor LibraryMaintenanceRepository: DictionaryRepositoryProtocol {
    private let bundleValue: DictionaryBundle
    private let supportsMaintenanceValue: Bool
    private let metadataValue: [String: String]?

    var clearCacheCount = 0
    var rebuildCount = 0
    var clearInstalledCount = 0

    init(bundle: DictionaryBundle, supportsMaintenance: Bool, metadata: [String: String]? = nil) {
        self.bundleValue = bundle
        self.supportsMaintenanceValue = supportsMaintenance
        self.metadataValue = metadata
    }

    func loadBundle() async throws -> DictionaryBundle {
        bundleValue
    }

    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry] {
        []
    }

    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        nil
    }

    func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        []
    }

    func entry(id: Int64) async throws -> DictionaryEntry? {
        nil
    }

    func metadata() async throws -> [String: String]? {
        metadataValue
    }

    func clearBundleCache() async {
        clearCacheCount += 1
    }

    func supportsLocalMaintenance() async -> Bool {
        supportsMaintenanceValue
    }

    func rebuildInstalledDatabase() async throws {
        rebuildCount += 1
    }

    func clearInstalledDatabase() async throws {
        clearInstalledCount += 1
    }
}
