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

    var clearCacheCount = 0
    var rebuildCount = 0
    var clearInstalledCount = 0

    init(bundle: DictionaryBundle, supportsMaintenance: Bool) {
        self.bundleValue = bundle
        self.supportsMaintenanceValue = supportsMaintenance
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
