import Foundation

public protocol SearchHistoryStoring: Sendable {
    func load() async -> [String]
    func save(_ history: [String]) async
    func clear() async
}

public actor UserDefaultsSearchHistoryStore: SearchHistoryStoring {
    public static let recentSearchHistoryKey = "recent_search_history"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() async -> [String] {
        guard let values = defaults.array(forKey: Self.recentSearchHistoryKey) as? [String] else {
            return []
        }
        return values
    }

    public func save(_ history: [String]) async {
        defaults.set(history, forKey: Self.recentSearchHistoryKey)
    }

    public func clear() async {
        defaults.removeObject(forKey: Self.recentSearchHistoryKey)
    }
}
