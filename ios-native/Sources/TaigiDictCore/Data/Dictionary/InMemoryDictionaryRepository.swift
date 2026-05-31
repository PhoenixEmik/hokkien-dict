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
        findLinkedEntries(rawWord).first
    }

    public func findLinkedEntries(_ rawWord: String) -> [DictionaryEntry] {
        let query = TextNormalization.normalizeQuery(rawWord)
        guard !query.isEmpty, !bundle.isDatabaseBacked else {
            return []
        }

        let exactHanjiMatches = bundle.entries.filter {
            TextNormalization.normalizeQuery($0.hanji) == query
        }
        if !exactHanjiMatches.isEmpty {
            return preferredLinkedEntries(from: exactHanjiMatches)
        }

        let variantMatches = bundle.entries.filter {
            $0.variantChars.contains(where: { TextNormalization.normalizeQuery($0) == query })
        }
        if !variantMatches.isEmpty {
            return preferredLinkedEntries(from: variantMatches)
        }

        let romanizationMatches = bundle.entries.filter {
            TextNormalization.normalizeQuery($0.romanization) == query
        }
        return preferredLinkedEntries(from: romanizationMatches)
    }

    private func preferredLinkedEntry(from entries: [DictionaryEntry]) -> DictionaryEntry? {
        preferredLinkedEntries(from: entries).first
    }

    private func preferredLinkedEntries(from entries: [DictionaryEntry]) -> [DictionaryEntry] {
        entries.sorted { lhs, rhs in
            linkedEntryPriority(lhs) < linkedEntryPriority(rhs)
        }
    }

    private func linkedEntryPriority(_ entry: DictionaryEntry) -> (Int, Int64) {
        (
            entryHasDisplayableSense(entry) ? 0 : (entry.aliasTargetEntryID != nil ? 1 : 2),
            entry.id
        )
    }

    private func entryHasDisplayableSense(_ entry: DictionaryEntry) -> Bool {
        entry.senses.contains { sense in
            !sense.partOfSpeech.isEmpty ||
            !sense.definition.isEmpty ||
            !sense.examples.isEmpty
        }
    }
}
