import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class DictionarySearchViewModel {
    public var searchText = ""
    public var normalizedQuery = ""
    public var isLoading = false
    public var isSearching = false
    public var results: [DictionaryEntry] = []
    public var selectedEntry: DictionaryEntry?
    public var detailEntry: DictionaryEntry?
    public var searchHistory: [String] = []
    public var libraryPhase: DictionaryLibraryPhase = .idle
    public var errorMessage: String?
    public private(set) var appLocale: AppLocale

    public let library: DictionaryLibrary
    private let conversionService: (any ChineseConversionProviding)?
    private let searchHistoryStore: any SearchHistoryStoring
    private var searchTask: Task<Void, Never>?

    public init(
        library: DictionaryLibrary,
        appLocale: AppLocale = .traditionalChinese,
        conversionService: (any ChineseConversionProviding)? = nil,
        searchHistoryStore: any SearchHistoryStoring = UserDefaultsSearchHistoryStore()
    ) {
        self.library = library
        self.appLocale = appLocale
        self.conversionService = conversionService
        self.searchHistoryStore = searchHistoryStore
    }

    public convenience init(
        repository: any DictionaryRepositoryProtocol,
        appLocale: AppLocale = .traditionalChinese,
        conversionService: (any ChineseConversionProviding)? = nil,
        searchHistoryStore: any SearchHistoryStoring = UserDefaultsSearchHistoryStore()
    ) {
        self.init(
            library: DictionaryLibrary(repository: repository),
            appLocale: appLocale,
            conversionService: conversionService,
            searchHistoryStore: searchHistoryStore
        )
    }

    public func setAppLocale(_ locale: AppLocale) {
        guard appLocale != locale else {
            return
        }

        appLocale = locale
        if !normalizedQuery.isEmpty {
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                await runSearch(searchText, saveHistory: false)
            }
        }
    }

    public func load() async {
        isLoading = true
        libraryPhase = await library.prepare()
        isLoading = false
        searchHistory = normalizeHistory(await searchHistoryStore.load())

        if case let .failed(message) = libraryPhase {
            errorMessage = message
        }
    }

    public func scheduleSearch() {
        searchTask?.cancel()
        let query = searchText
        let normalized = TextNormalization.normalizeQuery(query)
        normalizedQuery = normalized

        guard !normalized.isEmpty else {
            results = []
            selectedEntry = nil
            detailEntry = nil
            isSearching = false
            return
        }

        searchTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                await runSearch(query, saveHistory: false)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = String(describing: error)
                isSearching = false
            }
        }
    }

    public func submitSearch() {
        searchTask?.cancel()
        let query = searchText
        searchTask = Task { @MainActor in
            await runSearch(query, saveHistory: true)
        }
    }

    public func applyHistoryQuery(_ query: String) {
        searchText = query
        submitSearch()
    }

    public func clearSearchHistory() async {
        searchHistory = []
        await searchHistoryStore.clear()
    }

    public func resetAfterMaintenance() async {
        searchTask?.cancel()
        await library.reset()

        searchText = ""
        normalizedQuery = ""
        isLoading = false
        isSearching = false
        results = []
        selectedEntry = nil
        detailEntry = nil
        libraryPhase = .idle
        errorMessage = nil
    }

    public func select(_ entry: DictionaryEntry) {
        selectedEntry = entry
        detailEntry = entry
    }

    private func runSearch(_ query: String, saveHistory: Bool) async {
        let normalized = TextNormalization.normalizeQuery(query)
        normalizedQuery = normalized

        guard !normalized.isEmpty else {
            results = []
            selectedEntry = nil
            detailEntry = nil
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let locale = appLocale
            let converter = conversionService
            let normalizedQuery = await DictionaryDisplayLocalization.normalizeLookupWord(
                query,
                locale: locale,
                converter: converter
            )
            let found = try await library.search(
                normalizedQuery,
                limit: DictionarySearchService.defaultLimit
            )
            let displayResults = await found.asyncMap { entry in
                await DictionaryDisplayLocalization.translateEntry(
                    entry,
                    locale: locale,
                    converter: converter
                )
            }
            results = displayResults
            selectedEntry = displayResults.first
            if saveHistory, !displayResults.isEmpty {
                await saveHistoryItem(query)
            }
        } catch {
            results = []
            selectedEntry = nil
            errorMessage = String(describing: error)
        }

        isSearching = false
    }

    private func saveHistoryItem(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        searchHistory = [trimmed] + searchHistory.filter { $0 != trimmed }
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }

        await searchHistoryStore.save(searchHistory)
    }

    private func normalizeHistory(_ values: [String]) -> [String] {
        var deduplicated: [String] = []
        deduplicated.reserveCapacity(min(values.count, 10))

        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !deduplicated.contains(trimmed) else {
                continue
            }
            deduplicated.append(trimmed)
            if deduplicated.count == 10 {
                break
            }
        }

        return deduplicated
    }
}

private extension Array {
    func asyncMap<T>(_ transform: @escaping (Element) async -> T) async -> [T] {
        var values: [T] = []
        values.reserveCapacity(count)
        for element in self {
            values.append(await transform(element))
        }
        return values
    }
}
