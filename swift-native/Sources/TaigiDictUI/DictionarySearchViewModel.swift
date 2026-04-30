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

    private let library: DictionaryLibrary
    private var searchTask: Task<Void, Never>?

    public init(library: DictionaryLibrary) {
        self.library = library
    }

    public convenience init(repository: any DictionaryRepositoryProtocol) {
        self.init(library: DictionaryLibrary(repository: repository))
    }

    public func load() async {
        isLoading = true
        libraryPhase = await library.prepare()
        isLoading = false

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

    public func clearSearchHistory() {
        searchHistory = []
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
            let found = try await library.search(query, limit: DictionarySearchService.defaultLimit)
            results = found
            selectedEntry = found.first
            if saveHistory, !found.isEmpty {
                saveHistoryItem(query)
            }
        } catch {
            results = []
            selectedEntry = nil
            errorMessage = String(describing: error)
        }

        isSearching = false
    }

    private func saveHistoryItem(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        searchHistory = [trimmed] + searchHistory.filter { $0 != trimmed }
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }
    }
}
