import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadCapabilitiesReadsRepositorySupport() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.loadCapabilities()

        XCTAssertTrue(viewModel.supportsDataMaintenance)
    }

    func testRunRebuildReportsSuccessMessage() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        let result = await viewModel.run(.rebuild)
        let rebuildCount = await repository.rebuildCount

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.statusMessage, "本機辭典資料已重建。")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(rebuildCount, 1)
    }

    func testRunClearReportsSuccessMessage() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        let result = await viewModel.run(.clear)
        let clearInstalledCount = await repository.clearInstalledCount

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.statusMessage, "本機辭典資料已清除。")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(clearInstalledCount, 1)
    }

    func testRunReportsErrorWhenMaintenanceFails() async {
        let repository = SettingsRepository(
            supportsMaintenance: true,
            rebuildError: NSError(domain: "SettingsViewModelTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "injected rebuild failure",
            ])
        )
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        let result = await viewModel.run(.rebuild)

        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.statusMessage)
    }
}

private actor SettingsRepository: DictionaryRepositoryProtocol {
    private let supportsMaintenanceValue: Bool
    private let rebuildError: Error?

    var rebuildCount = 0
    var clearInstalledCount = 0

    init(supportsMaintenance: Bool, rebuildError: Error? = nil) {
        self.supportsMaintenanceValue = supportsMaintenance
        self.rebuildError = rebuildError
    }

    func loadBundle() async throws -> DictionaryBundle {
        DictionaryBundle(entryCount: 0, senseCount: 0, exampleCount: 0, entries: [])
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

    func clearBundleCache() async {}

    func supportsLocalMaintenance() async -> Bool {
        supportsMaintenanceValue
    }

    func rebuildInstalledDatabase() async throws {
        rebuildCount += 1
        if let rebuildError {
            throw rebuildError
        }
    }

    func clearInstalledDatabase() async throws {
        clearInstalledCount += 1
    }
}
