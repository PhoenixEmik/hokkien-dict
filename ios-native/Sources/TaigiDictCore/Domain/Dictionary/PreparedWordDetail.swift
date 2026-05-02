import Foundation

public struct PreparedWordDetail: Sendable {
    public var entry: DictionaryEntry
    public var resolvedEntryID: Int64
    public var openableWords: Set<String>

    public init(
        entry: DictionaryEntry,
        resolvedEntryID: Int64,
        openableWords: Set<String>
    ) {
        self.entry = entry
        self.resolvedEntryID = resolvedEntryID
        self.openableWords = openableWords
    }

    public func canOpenWord(_ word: String) -> Bool {
        openableWords.contains(word)
    }
}
