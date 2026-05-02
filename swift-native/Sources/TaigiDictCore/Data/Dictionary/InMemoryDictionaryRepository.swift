import Foundation

public actor InMemoryDictionaryRepository {
    private let bundle: DictionaryBundle
    private let entriesByID: [Int64: DictionaryEntry]
    private let searchIndex: [DictionarySearchRow]

    public init(bundle: DictionaryBundle) {
        self.bundle = bundle
        self.entriesByID = Dictionary(uniqueKeysWithValues: bundle.entries.map { ($0.id, $0) })
        self.searchIndex = DictionarySearchService.buildSearchIndex(entries: bundle.entries)
    }

    public func search(_ rawQuery: String, limit: Int = DictionarySearchService.defaultLimit) -> [DictionaryEntry] {
        DictionarySearchService.searchEntryIDs(index: searchIndex, query: rawQuery, limit: limit)
            .compactMap { entriesByID[$0] }
    }

    public func entries(ids rawIDs: [Int64]) -> [DictionaryEntry] {
        var seen = Set<Int64>()
        return rawIDs.compactMap { id in
            guard seen.insert(id).inserted else {
                return nil
            }
            return entriesByID[id]
        }
    }

    public func entry(id: Int64) -> DictionaryEntry? {
        entriesByID[id]
    }

    public func findLinkedEntry(_ rawWord: String) -> DictionaryEntry? {
        let query = TextNormalization.normalizeQuery(rawWord)
        guard !query.isEmpty, !bundle.isDatabaseBacked else {
            return nil
        }

        var romanizationMatch: DictionaryEntry?

        for entry in bundle.entries {
            if TextNormalization.normalizeQuery(entry.hanji) == query {
                return entry
            }

            if entry.variantChars.contains(where: { TextNormalization.normalizeQuery($0) == query }) {
                return entry
            }

            if romanizationMatch == nil, TextNormalization.normalizeQuery(entry.romanization) == query {
                romanizationMatch = entry
            }
        }

        return romanizationMatch
    }
}
