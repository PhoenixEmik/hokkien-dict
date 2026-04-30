import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadCapabilitiesReadsRepositorySupport() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(
            library: DictionaryLibrary(repository: repository),
            dateFormatter: FakeDateFormatter()
        )

        await viewModel.loadCapabilities()

        XCTAssertTrue(viewModel.supportsDataMaintenance)
        XCTAssertEqual(viewModel.librarySummary, DictionaryLibrarySummary(entryCount: 2, senseCount: 3, exampleCount: 4))
        XCTAssertEqual(
            viewModel.libraryMetadata,
            DictionaryLibraryMetadata(
                builtAt: "2026-04-30T00:00:00Z",
                sourceModifiedAt: "2026-04-29T00:00:00Z"
            )
        )
        XCTAssertEqual(viewModel.metadataBuiltAtDisplay, "displayed(2026-04-30T00:00:00Z)")
        XCTAssertEqual(viewModel.metadataSourceModifiedAtDisplay, "displayed(2026-04-29T00:00:00Z)")
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
        let viewModel = SettingsViewModel(
            library: DictionaryLibrary(repository: repository),
            dateFormatter: FakeDateFormatter()
        )

        let result = await viewModel.run(.clear)
        let clearInstalledCount = await repository.clearInstalledCount

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.statusMessage, "本機辭典資料已清除。")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.librarySummary)
        XCTAssertNil(viewModel.libraryMetadata)
        XCTAssertNil(viewModel.metadataBuiltAtDisplay)
        XCTAssertNil(viewModel.metadataSourceModifiedAtDisplay)
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

    func testClearConfirmationFlowRequiresExplicitConfirm() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.loadCapabilities()
        viewModel.requestClearConfirmation()
        let clearInstalledCount = await repository.clearInstalledCount

        XCTAssertTrue(viewModel.isClearConfirmationPresented)
        XCTAssertEqual(clearInstalledCount, 0)

        viewModel.cancelClearConfirmation()
        XCTAssertFalse(viewModel.isClearConfirmationPresented)
    }

    func testConfirmClearRunsClearAndDismissesConfirmation() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let viewModel = SettingsViewModel(library: DictionaryLibrary(repository: repository))

        await viewModel.loadCapabilities()
        viewModel.requestClearConfirmation()
        let result = await viewModel.confirmClear()
        let clearInstalledCount = await repository.clearInstalledCount

        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isClearConfirmationPresented)
        XCTAssertEqual(clearInstalledCount, 1)
    }
}

private struct FakeDateFormatter: SettingsDateFormatting {
    func displayString(from iso8601: String?) -> String? {
        guard let iso8601 else {
            return nil
        }
        return "displayed(\(iso8601))"
    }
}

private actor SettingsRepository: DictionaryRepositoryProtocol {
    private let supportsMaintenanceValue: Bool
    private let rebuildError: Error?
    private var metadataValue: [String: String]? = [
        "built_at": "2026-04-30T00:00:00Z",
        "source_modified_at": "2026-04-29T00:00:00Z",
    ]

    var rebuildCount = 0
    var clearInstalledCount = 0

    init(supportsMaintenance: Bool, rebuildError: Error? = nil) {
        self.supportsMaintenanceValue = supportsMaintenance
        self.rebuildError = rebuildError
    }

    func loadBundle() async throws -> DictionaryBundle {
        DictionaryBundle(entryCount: 2, senseCount: 3, exampleCount: 4, entries: [])
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
        metadataValue = nil
    }
}
