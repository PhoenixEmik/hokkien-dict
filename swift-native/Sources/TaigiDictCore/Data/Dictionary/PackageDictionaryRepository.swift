import Foundation

public actor PackageDictionaryRepository: DictionaryRepositoryProtocol {
    private let packageDirectory: URL
    private let loader: DictionaryPackageLoader
    private var cachedBundle: DictionaryBundle?
    private var cachedRepository: InMemoryDictionaryRepository?

    public init(
        packageDirectory: URL,
        loader: DictionaryPackageLoader = DictionaryPackageLoader()
    ) {
        self.packageDirectory = packageDirectory
        self.loader = loader
    }

    public func loadBundle() async throws -> DictionaryBundle {
        if let cachedBundle {
            return cachedBundle
        }

        let bundle = try loader.loadBundle(from: packageDirectory)
        cachedBundle = bundle
        cachedRepository = InMemoryDictionaryRepository(bundle: bundle)
        return bundle
    }

    public func search(
        _ rawQuery: String,
        limit: Int = DictionarySearchService.defaultLimit,
        offset: Int = 0
    ) async throws -> [DictionaryEntry] {
        let repository = try await repository()
        let results = await repository.search(rawQuery, limit: limit + max(offset, 0))
        guard offset > 0 else {
            return results
        }
        return Array(results.dropFirst(offset))
    }

    public func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        try await repository().findLinkedEntry(rawWord)
    }

    public func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        try await repository().entries(ids: ids)
    }

    public func entry(id: Int64) async throws -> DictionaryEntry? {
        try await repository().entry(id: id)
    }

    public func clearBundleCache() async {
        cachedBundle = nil
        cachedRepository = nil
    }

    private func repository() async throws -> InMemoryDictionaryRepository {
        if let cachedRepository {
            return cachedRepository
        }
        _ = try await loadBundle()
        return cachedRepository!
    }
}
