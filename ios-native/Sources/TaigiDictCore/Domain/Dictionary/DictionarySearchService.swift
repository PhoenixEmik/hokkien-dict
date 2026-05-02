import Foundation

public struct DictionarySearchRow: Sendable {
    public var entryID: Int64
    public var headwords: [String]
    public var definitions: [String]

    public init(entryID: Int64, headwords: [String], definitions: [String]) {
        self.entryID = entryID
        self.headwords = headwords
        self.definitions = definitions
    }
}

public enum DictionarySearchService {
    public static let defaultLimit = 60

    public static func buildSearchIndex(entries: [DictionaryEntry]) -> [DictionarySearchRow] {
        entries.map { entry in
            DictionarySearchRow(
                entryID: entry.id,
                headwords: headwordFields(for: entry),
                definitions: definitionFields(for: entry)
            )
        }
    }

    public static func searchEntryIDs(
        index: [DictionarySearchRow],
        query rawQuery: String,
        limit: Int = defaultLimit
    ) -> [Int64] {
        let query = TextNormalization.normalizeQuery(rawQuery)
        guard !query.isEmpty else {
            return []
        }

        return index
            .compactMap { match(row: $0, query: query) }
            .sorted()
            .prefix(limit)
            .map(\.entryID)
    }

    private static func match(row: DictionarySearchRow, query: String) -> ScoredSearchHit? {
        if let headwordMatch = bestMatchLength(fields: row.headwords, query: query) {
            let score = headwordMatch == query.count ? 0 : 1
            return ScoredSearchHit(entryID: row.entryID, score: score, matchedLength: headwordMatch)
        }

        guard let definitionMatch = bestMatchLength(fields: row.definitions, query: query) else {
            return nil
        }

        return ScoredSearchHit(entryID: row.entryID, score: 2, matchedLength: definitionMatch)
    }

    private static func headwordFields(for entry: DictionaryEntry) -> [String] {
        uniqueNonEmpty([
            TextNormalization.normalizeQuery(entry.hanji),
            TextNormalization.normalizeQuery(entry.romanization),
        ])
    }

    private static func definitionFields(for entry: DictionaryEntry) -> [String] {
        let senseFields = entry.senses.flatMap { sense in
            [sense.definition] + sense.definitionSynonyms + sense.definitionAntonyms +
                sense.examples.flatMap { [$0.hanji, $0.romanization, $0.mandarin] }
        }

        return uniqueNonEmpty(
            [entry.mandarinSearch] + senseFields
                .map(TextNormalization.normalizeQuery)
        )
    }

    private static func bestMatchLength(fields: [String], query: String) -> Int? {
        fields.reduce(nil) { bestLength, field in
            guard !field.isEmpty, !query.isEmpty, field.contains(query) else {
                return bestLength
            }

            if let bestLength {
                return min(bestLength, field.count)
            }

            return field.count
        }
    }

    private static func uniqueNonEmpty(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values where !value.isEmpty && seen.insert(value).inserted {
            result.append(value)
        }

        return result
    }
}

private struct ScoredSearchHit: Comparable {
    var entryID: Int64
    var score: Int
    var matchedLength: Int

    static func < (left: ScoredSearchHit, right: ScoredSearchHit) -> Bool {
        if left.score != right.score {
            return left.score < right.score
        }

        if left.matchedLength != right.matchedLength {
            return left.matchedLength < right.matchedLength
        }

        return left.entryID < right.entryID
    }
}
