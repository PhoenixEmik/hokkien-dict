import Foundation

public protocol BookmarksStoreProtocol: Sendable {
    func bookmarkedEntryIDs() async -> [Int64]
    func isBookmarked(_ entryID: Int64) async -> Bool
    @discardableResult
    func toggleBookmark(entryID: Int64) async -> Bool
    func removeBookmarks(entryIDs: [Int64]) async
}

public actor BookmarkStore: BookmarksStoreProtocol {
    private let userDefaults: UserDefaults
    private let storageKey: String

    public init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "bookmarked_entry_ids"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    public func bookmarkedEntryIDs() async -> [Int64] {
        readIDs()
    }

    public func isBookmarked(_ entryID: Int64) async -> Bool {
        readIDs().contains(entryID)
    }

    @discardableResult
    public func toggleBookmark(entryID: Int64) async -> Bool {
        var ids = readIDs()
        if let existingIndex = ids.firstIndex(of: entryID) {
            ids.remove(at: existingIndex)
            write(ids)
            return false
        }

        ids.insert(entryID, at: 0)
        write(ids)
        return true
    }

    public func removeBookmarks(entryIDs: [Int64]) async {
        let blocked = Set(entryIDs)
        guard !blocked.isEmpty else {
            return
        }

        let remaining = readIDs().filter { !blocked.contains($0) }
        write(remaining)
    }

    private func readIDs() -> [Int64] {
        if let numbers = userDefaults.array(forKey: storageKey) as? [NSNumber] {
            return numbers.map(\.int64Value)
        }
        return []
    }

    private func write(_ ids: [Int64]) {
        userDefaults.set(ids, forKey: storageKey)
    }
}
