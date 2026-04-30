import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadCapabilitiesReadsRepositorySupport() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let settingsStore = TestAppSettingsStore(
            snapshot: AppSettingsSnapshot(
                interfaceLocale: .english,
                themePreference: .dark,
                readingTextScale: 1.2
            )
        )
        let viewModel = SettingsViewModel(
            library: DictionaryLibrary(repository: repository),
            settingsStore: settingsStore,
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
        XCTAssertEqual(viewModel.selectedLocale, .english)
        XCTAssertEqual(viewModel.selectedThemePreference, .dark)
        XCTAssertEqual(viewModel.readingTextScale, 1.2)
    }

    func testSettersPersistUpdatedPreferences() async {
        let repository = SettingsRepository(supportsMaintenance: true)
        let settingsStore = TestAppSettingsStore()
        let viewModel = SettingsViewModel(
            library: DictionaryLibrary(repository: repository),
            settingsStore: settingsStore
        )

        await viewModel.setLocale(.simplifiedChinese)
        await viewModel.setThemePreference(.amoled)
        await viewModel.setReadingTextScale(1.36)
        let persisted = await settingsStore.load()

        XCTAssertEqual(viewModel.selectedLocale, .simplifiedChinese)
        XCTAssertEqual(viewModel.selectedThemePreference, .amoled)
        XCTAssertEqual(viewModel.readingTextScale, 1.4)
        XCTAssertEqual(persisted.interfaceLocale, .simplifiedChinese)
        XCTAssertEqual(persisted.themePreference, .amoled)
        XCTAssertEqual(persisted.readingTextScale, 1.4)
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

private actor TestAppSettingsStore: AppSettingsStoring {
    private var snapshot: AppSettingsSnapshot

    init(snapshot: AppSettingsSnapshot = AppSettingsSnapshot()) {
        self.snapshot = snapshot
    }

    func load() async -> AppSettingsSnapshot {
        snapshot
    }

    func setInterfaceLocale(_ locale: AppLocale) async {
        snapshot.interfaceLocale = locale
    }

    func setThemePreference(_ preference: AppThemePreference) async {
        snapshot.themePreference = preference
    }

    func setReadingTextScale(_ value: Double) async {
        snapshot.readingTextScale = AppSettingsSnapshot.snapReadingTextScale(value)
    }
}
