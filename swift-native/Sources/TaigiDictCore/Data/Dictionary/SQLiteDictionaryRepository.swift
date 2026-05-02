import Foundation
import GRDB

public enum SQLiteDictionaryRepositoryError: Error, Equatable {
    case missingDatabase(URL)
}

public actor SQLiteDictionaryRepository: DictionaryRepositoryProtocol {
    private let databaseURL: URL
    private var cachedBundle: DictionaryBundle?
    private var dbQueue: DatabaseQueue?

    public init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }

    public func loadBundle() async throws -> DictionaryBundle {
        if let cachedBundle {
            return cachedBundle
        }

        let dbQueue = try tryDatabaseQueue()
        let metadata = try await dbQueue.read { db in
            try Self.loadMetadata(from: db)
        }
        let bundle = DictionaryBundle(
            entryCount: metadata.entryCount,
            senseCount: metadata.senseCount,
            exampleCount: metadata.exampleCount,
            entries: [],
            databasePath: databaseURL.path
        )
        cachedBundle = bundle
        return bundle
    }

    public func search(
        _ rawQuery: String,
        limit: Int = DictionarySearchService.defaultLimit,
        offset: Int = 0
    ) async throws -> [DictionaryEntry] {
        let normalizedQuery = TextNormalization.normalizeQuery(rawQuery)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        let dbQueue = try tryDatabaseQueue()
        return try await dbQueue.read { db in
            let candidateIDs = try Self.searchCandidateIDs(
                normalizedQuery: normalizedQuery,
                limit: max(limit + max(offset, 0), DictionarySearchService.defaultLimit) * 6,
                in: db
            )
            guard !candidateIDs.isEmpty else {
                return []
            }

            let candidateEntries = try Self.fetchEntries(ids: candidateIDs, from: db)
            let rankedIDs = DictionarySearchService.searchEntryIDs(
                index: DictionarySearchService.buildSearchIndex(entries: candidateEntries),
                query: rawQuery,
                limit: limit + max(offset, 0)
            )

            let entriesByID = Dictionary(uniqueKeysWithValues: candidateEntries.map { ($0.id, $0) })
            return Array(rankedIDs.dropFirst(max(offset, 0)).prefix(limit)).compactMap { entriesByID[$0] }
        }
    }

    public func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        let query = TextNormalization.normalizeQuery(rawWord)
        guard !query.isEmpty else {
            return nil
        }

        let dbQueue = try tryDatabaseQueue()
        return try await dbQueue.read { db in
            let candidateIDs = try Int64.fetchAll(
                db,
                sql: """
                SELECT DISTINCT id
                FROM dictionary_entries
                WHERE hanji = ?
                   OR variant_chars LIKE ? ESCAPE '\\'
                   OR hokkien_search LIKE ? ESCAPE '\\'
                LIMIT 64
                """,
                arguments: [
                    rawWord,
                    "%\(Self.escapeLike(rawWord))%",
                    "%\(Self.escapeLike(query))%",
                ]
            )

            let entries = try Self.fetchEntries(ids: candidateIDs, from: db)
            var romanizationMatch: DictionaryEntry?

            for entry in entries {
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

    public func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        guard !ids.isEmpty else {
            return []
        }

        let dbQueue = try tryDatabaseQueue()
        return try await dbQueue.read { db in
            try Self.fetchEntries(ids: ids, from: db)
        }
    }

    public func entry(id: Int64) async throws -> DictionaryEntry? {
        try await entries(ids: [id]).first
    }

    public func metadata() async throws -> [String: String]? {
        let dbQueue = try tryDatabaseQueue()
        return try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT key, value FROM dictionary_metadata")
            guard !rows.isEmpty else {
                return nil
            }
            return Dictionary(uniqueKeysWithValues: rows.map { row in
                let key: String = row["key"]
                let value: String = row["value"]
                return (key, value)
            })
        }
    }

    public func clearBundleCache() async {
        cachedBundle = nil
        dbQueue = nil
    }

    private static func loadMetadata(from db: Database) throws -> (entryCount: Int, senseCount: Int, exampleCount: Int) {
        let rows = try Row.fetchAll(
            db,
            sql: "SELECT key, value FROM dictionary_metadata WHERE key IN ('entry_count', 'sense_count', 'example_count')"
        )
        let values = Dictionary(uniqueKeysWithValues: rows.map { row in
            let key: String = row["key"]
            let value: String = row["value"]
            return (key, value)
        })

        if let entryCount = values["entry_count"].flatMap(Int.init),
           let senseCount = values["sense_count"].flatMap(Int.init),
           let exampleCount = values["example_count"].flatMap(Int.init) {
            return (entryCount, senseCount, exampleCount)
        }

        return (
            try countRows(in: "dictionary_entries", db: db),
            try countRows(in: "dictionary_senses", db: db),
            try countRows(in: "dictionary_examples", db: db)
        )
    }

    private static func countRows(in tableName: String, db: Database) throws -> Int {
        try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(tableName)") ?? 0
    }

    private static func searchCandidateIDs(
        normalizedQuery: String,
        limit: Int,
        in db: Database
    ) throws -> [Int64] {
        let pattern = "%\(Self.escapeLike(normalizedQuery))%"
        return try Int64.fetchAll(
            db,
            sql: """
            SELECT DISTINCT e.id
            FROM dictionary_entries e
            LEFT JOIN dictionary_senses s ON s.entry_id = e.id
            LEFT JOIN dictionary_examples x ON x.entry_id = e.id
            WHERE e.hokkien_search LIKE ? ESCAPE '\\'
               OR e.mandarin_search LIKE ? ESCAPE '\\'
               OR e.hanji LIKE ? ESCAPE '\\'
               OR e.romanization LIKE ? ESCAPE '\\'
               OR s.definition LIKE ? ESCAPE '\\'
               OR x.hanji LIKE ? ESCAPE '\\'
               OR x.romanization LIKE ? ESCAPE '\\'
               OR x.mandarin LIKE ? ESCAPE '\\'
            ORDER BY e.id
            LIMIT ?
            """,
            arguments: [pattern, pattern, pattern, pattern, pattern, pattern, pattern, pattern, limit]
        )
    }

    private static func fetchEntries(ids rawIDs: [Int64], from db: Database) throws -> [DictionaryEntry] {
        let ids = Self.uniqueIDs(rawIDs)
        guard !ids.isEmpty else {
            return []
        }

        let entryRows = try fetchEntryRows(ids: ids, from: db)
        guard !entryRows.isEmpty else {
            return []
        }

        let examplesBySense = try fetchExamples(ids: ids, from: db)
        let sensesByEntry = try Self.fetchSenses(ids: ids, examplesBySense: examplesBySense, from: db)
        let rowsByID = Dictionary(uniqueKeysWithValues: entryRows.map { ($0.id, $0) })

        return ids.reduce(into: [DictionaryEntry]()) { collected, id in
            guard let row = rowsByID[id] else {
                return
            }
            collected.append(
                DictionaryEntry(
                    id: row.id,
                    type: row.type,
                    hanji: row.hanji,
                    romanization: row.romanization,
                    category: row.category,
                    audioID: row.audioID,
                    hokkienSearch: row.hokkienSearch,
                    mandarinSearch: row.mandarinSearch,
                    variantChars: decodeStringArray(row.variantCharsJSON),
                    wordSynonyms: decodeStringArray(row.wordSynonymsJSON),
                    wordAntonyms: decodeStringArray(row.wordAntonymsJSON),
                    alternativePronunciations: decodeStringArray(row.alternativePronunciationsJSON),
                    contractedPronunciations: decodeStringArray(row.contractedPronunciationsJSON),
                    colloquialPronunciations: decodeStringArray(row.colloquialPronunciationsJSON),
                    phoneticDifferences: decodeStringArray(row.phoneticDifferencesJSON),
                    vocabularyComparisons: decodeStringArray(row.vocabularyComparisonsJSON),
                    aliasTargetEntryID: row.aliasTargetEntryID,
                    senses: sensesByEntry[id] ?? []
                )
            )
        }
    }

    private static func fetchEntryRows(ids: [Int64], from db: Database) throws -> [EntryRow] {
        let idList = Self.sqlList(ids)
        let rows = try Row.fetchAll(
            db,
            sql: """
              SELECT id, type, hanji, romanization, category, audio_id,
                  variant_chars, word_synonyms, word_antonyms,
                  alternative_pronunciations, contracted_pronunciations,
                  colloquial_pronunciations, phonetic_differences,
                  vocabulary_comparisons, alias_target_entry_id,
                  hokkien_search, mandarin_search
              FROM dictionary_entries
              WHERE id IN (\(idList))
              """
        )
        return rows.map { row in
            EntryRow(
                id: row["id"],
                type: row["type"],
                hanji: row["hanji"],
                romanization: row["romanization"],
                category: row["category"],
                audioID: row["audio_id"],
                variantCharsJSON: row["variant_chars"],
                wordSynonymsJSON: row["word_synonyms"],
                wordAntonymsJSON: row["word_antonyms"],
                alternativePronunciationsJSON: row["alternative_pronunciations"],
                contractedPronunciationsJSON: row["contracted_pronunciations"],
                colloquialPronunciationsJSON: row["colloquial_pronunciations"],
                phoneticDifferencesJSON: row["phonetic_differences"],
                vocabularyComparisonsJSON: row["vocabulary_comparisons"],
                aliasTargetEntryID: row["alias_target_entry_id"],
                hokkienSearch: row["hokkien_search"],
                mandarinSearch: row["mandarin_search"]
            )
        }
    }

    private static func fetchSenses(
        ids: [Int64],
        examplesBySense: [SenseKey: [DictionaryExample]],
        from db: Database
    ) throws -> [Int64: [DictionarySense]] {
        let idList = Self.sqlList(ids)
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT entry_id, sense_id, part_of_speech, definition,
                   definition_synonyms, definition_antonyms
            FROM dictionary_senses
            WHERE entry_id IN (\(idList))
            ORDER BY entry_id, sense_id
            """
        )
        var sensesByEntry: [Int64: [DictionarySense]] = [:]
        for row in rows {
            let entryID: Int64 = row["entry_id"]
            let senseID: Int64 = row["sense_id"]
            let key = SenseKey(entryID: entryID, senseID: senseID)
            let sense = DictionarySense(
                partOfSpeech: row["part_of_speech"],
                definition: row["definition"],
                definitionSynonyms: Self.decodeStringArray(row["definition_synonyms"]),
                definitionAntonyms: Self.decodeStringArray(row["definition_antonyms"]),
                examples: examplesBySense[key] ?? []
            )
            sensesByEntry[entryID, default: []].append(sense)
        }
        return sensesByEntry
    }

    private static func fetchExamples(ids: [Int64], from db: Database) throws -> [SenseKey: [DictionaryExample]] {
        let idList = Self.sqlList(ids)
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT entry_id, sense_id, hanji, romanization, mandarin, audio_id
            FROM dictionary_examples
            WHERE entry_id IN (\(idList))
            ORDER BY entry_id, sense_id, example_order, id
            """
        )
        var examplesBySense: [SenseKey: [DictionaryExample]] = [:]
        for row in rows {
            let entryID: Int64 = row["entry_id"]
            let senseID: Int64 = row["sense_id"]
            let key = SenseKey(entryID: entryID, senseID: senseID)
            let example = DictionaryExample(
                hanji: row["hanji"],
                romanization: row["romanization"],
                mandarin: row["mandarin"],
                audioID: row["audio_id"]
            )
            examplesBySense[key, default: []].append(example)
        }
        return examplesBySense
    }

        private static func decodeStringArray(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return values
    }

    private static func escapeLike(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private static func uniqueIDs(_ ids: [Int64]) -> [Int64] {
        var seen = Set<Int64>()
        return ids.filter { seen.insert($0).inserted }
    }

    private static func sqlList(_ ids: [Int64]) -> String {
        ids.map(String.init).joined(separator: ", ")
    }

    private func tryDatabaseQueue() throws -> DatabaseQueue {
        if let dbQueue {
            return dbQueue
        }
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            throw SQLiteDictionaryRepositoryError.missingDatabase(databaseURL)
        }
        let queue = try DictionaryDatabase.openQueue(at: databaseURL)
        dbQueue = queue
        return queue
    }
}

private struct EntryRow {
    var id: Int64
    var type: String
    var hanji: String
    var romanization: String
    var category: String
    var audioID: String
    var variantCharsJSON: String
    var wordSynonymsJSON: String
    var wordAntonymsJSON: String
    var alternativePronunciationsJSON: String
    var contractedPronunciationsJSON: String
    var colloquialPronunciationsJSON: String
    var phoneticDifferencesJSON: String
    var vocabularyComparisonsJSON: String
    var aliasTargetEntryID: Int64?
    var hokkienSearch: String
    var mandarinSearch: String
}

private struct SenseKey: Hashable {
    var entryID: Int64
    var senseID: Int64
}