import XCTest
import TaigiDictCore
@testable import TaigiDictUI

@MainActor
final class InitializationViewModelTests: XCTestCase {
    func testPrepareSetsReadyWhenDictionaryLibrarySucceeds() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let searchViewModel = DictionarySearchViewModel(repository: repository)
        let initializationViewModel = InitializationViewModel()

        await initializationViewModel.prepare(using: searchViewModel)

        XCTAssertEqual(initializationViewModel.phase, .ready)
        XCTAssertTrue(initializationViewModel.isReady)
        XCTAssertEqual(initializationViewModel.progress, 1)
        XCTAssertEqual(initializationViewModel.processedUnits, 1)
        XCTAssertEqual(initializationViewModel.totalUnits, 1)
        XCTAssertNil(initializationViewModel.errorMessage)
        XCTAssertEqual(initializationViewModel.databaseGeneration, 1)
    }

    func testPrepareSetsFailedWhenDictionaryLibraryFails() async {
        let searchViewModel = DictionarySearchViewModel(repository: FailingRepository())
        let initializationViewModel = InitializationViewModel()

        await initializationViewModel.prepare(using: searchViewModel)

        XCTAssertEqual(initializationViewModel.phase, .failed)
        XCTAssertFalse(initializationViewModel.isReady)
        guard case let .library(message)? = initializationViewModel.failureReason else {
            return XCTFail("Expected library failure reason")
        }
        XCTAssertTrue(message.contains("injected failure"))
        XCTAssertTrue(initializationViewModel.errorMessage?.contains("injected failure") == true)
        XCTAssertEqual(initializationViewModel.databaseGeneration, 0)
    }

    func testRetryResetsStateAndChangesTaskID() async {
        let searchViewModel = DictionarySearchViewModel(repository: FailingRepository())
        let initializationViewModel = InitializationViewModel()

        await initializationViewModel.prepare(using: searchViewModel)
        let firstTaskID = initializationViewModel.taskID

        initializationViewModel.retry()

        XCTAssertEqual(initializationViewModel.phase, .idle)
        XCTAssertNil(initializationViewModel.progress)
        XCTAssertEqual(initializationViewModel.processedUnits, 0)
        XCTAssertEqual(initializationViewModel.totalUnits, 0)
        XCTAssertNil(initializationViewModel.errorMessage)
        XCTAssertNil(initializationViewModel.failureReason)
        XCTAssertNotEqual(initializationViewModel.taskID, firstTaskID)
    }

    func testDatabaseGenerationDoesNotIncrementWhenAlreadyReady() async {
        let repository = InMemoryRepository(entries: [
            entry(id: 1, hanji: "辭典", romanization: "sû-tián", definition: "工具書"),
        ])
        let searchViewModel = DictionarySearchViewModel(repository: repository)
        let initializationViewModel = InitializationViewModel()

        await initializationViewModel.prepare(using: searchViewModel)
        await initializationViewModel.prepare(using: searchViewModel)

        XCTAssertEqual(initializationViewModel.databaseGeneration, 1)
    }
}

private actor InMemoryRepository: DictionaryRepositoryProtocol {
    private let bundle: DictionaryBundle
    private let repository: InMemoryDictionaryRepository

    init(entries: [DictionaryEntry]) {
        bundle = DictionaryBundle(
            entryCount: entries.count,
            senseCount: entries.reduce(0) { $0 + $1.senses.count },
            exampleCount: 0,
            entries: entries
        )
        repository = InMemoryDictionaryRepository(bundle: bundle)
    }

    func loadBundle() async throws -> DictionaryBundle {
        bundle
    }

    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry] {
        let results = await repository.search(rawQuery, limit: limit + max(offset, 0))
        return Array(results.dropFirst(max(offset, 0)))
    }

    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        await repository.findLinkedEntry(rawWord)
    }

    func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        await repository.entries(ids: ids)
    }

    func entry(id: Int64) async throws -> DictionaryEntry? {
        await repository.entry(id: id)
    }

    func clearBundleCache() async {}
}

private actor FailingRepository: DictionaryRepositoryProtocol {
    func loadBundle() async throws -> DictionaryBundle {
        throw NSError(domain: "InitializationViewModelTests", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "injected failure",
        ])
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
}

private func entry(
    id: Int64,
    hanji: String,
    romanization: String,
    definition: String
) -> DictionaryEntry {
    DictionaryEntry(
        id: id,
        type: "名詞",
        hanji: hanji,
        romanization: romanization,
        category: "主詞目",
        audioID: "",
        hokkienSearch: "\(hanji) \(romanization)",
        mandarinSearch: definition,
        senses: [
            DictionarySense(partOfSpeech: "名詞", definition: definition),
        ]
    )
}