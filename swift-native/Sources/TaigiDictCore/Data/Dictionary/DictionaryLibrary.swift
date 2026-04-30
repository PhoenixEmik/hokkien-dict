import Foundation

public enum DictionaryLibraryPhase: Equatable, Sendable {
    case idle
    case loading
    case ready(DictionaryLibrarySummary)
    case failed(String)
}

public struct DictionaryLibrarySummary: Equatable, Sendable {
    public var entryCount: Int
    public var senseCount: Int
    public var exampleCount: Int

    public init(entryCount: Int, senseCount: Int, exampleCount: Int) {
        self.entryCount = entryCount
        self.senseCount = senseCount
        self.exampleCount = exampleCount
    }
}

public struct DictionaryLibraryMetadata: Equatable, Sendable {
    public var builtAt: String?
    public var sourceModifiedAt: String?

    public init(builtAt: String?, sourceModifiedAt: String?) {
        self.builtAt = builtAt
        self.sourceModifiedAt = sourceModifiedAt
    }
}

public actor DictionaryLibrary {
    private let repository: any DictionaryRepositoryProtocol
    private var phaseStorage: DictionaryLibraryPhase = .idle

    public init(repository: any DictionaryRepositoryProtocol) {
        self.repository = repository
    }

    public var phase: DictionaryLibraryPhase {
        phaseStorage
    }

    public func currentSummary() -> DictionaryLibrarySummary? {
        guard case let .ready(summary) = phaseStorage else {
            return nil
        }
        return summary
    }

    public func metadata() async throws -> DictionaryLibraryMetadata? {
        guard let values = try await repository.metadata() else {
            return nil
        }
        return DictionaryLibraryMetadata(
            builtAt: nonEmpty(values["built_at"]),
            sourceModifiedAt: nonEmpty(values["source_modified_at"])
        )
    }

    @discardableResult
    public func prepare() async -> DictionaryLibraryPhase {
        switch phaseStorage {
        case .ready:
            return phaseStorage
        case .loading:
            return phaseStorage
        case .idle, .failed:
            break
        }

        phaseStorage = .loading
        do {
            let bundle = try await repository.loadBundle()
            let summary = DictionaryLibrarySummary(
                entryCount: bundle.entryCount,
                senseCount: bundle.senseCount,
                exampleCount: bundle.exampleCount
            )
            phaseStorage = .ready(summary)
        } catch {
            phaseStorage = .failed(String(describing: error))
        }
        return phaseStorage
    }

    public func search(_ query: String, limit: Int = DictionarySearchService.defaultLimit) async throws -> [DictionaryEntry] {
        try await repository.search(query, limit: limit, offset: 0)
    }

    public func findLinkedEntry(_ word: String) async throws -> DictionaryEntry? {
        try await repository.findLinkedEntry(word)
    }

    public func entry(id: Int64) async throws -> DictionaryEntry? {
        try await repository.entry(id: id)
    }

    public func supportsLocalMaintenance() async -> Bool {
        await repository.supportsLocalMaintenance()
    }

    public func rebuildInstalledDatabase() async throws {
        try await repository.rebuildInstalledDatabase()
        await repository.clearBundleCache()
        phaseStorage = .idle
    }

    public func clearInstalledDatabase() async throws {
        try await repository.clearInstalledDatabase()
        await repository.clearBundleCache()
        phaseStorage = .idle
    }

    public func reset() async {
        await repository.clearBundleCache()
        phaseStorage = .idle
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }
}
