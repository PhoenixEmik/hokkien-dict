import Foundation
import GRDB

public enum DictionaryImportError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case entryCountMismatch(expected: Int, actual: Int)
    case senseCountMismatch(expected: Int, actual: Int)
    case exampleCountMismatch(expected: Int, actual: Int)
}

public struct DictionaryImportProgress: Equatable, Sendable {
    public var processedEntries: Int
    public var totalEntries: Int

    public init(processedEntries: Int, totalEntries: Int) {
        self.processedEntries = max(processedEntries, 0)
        self.totalEntries = max(totalEntries, 1)
    }

    public var fraction: Double {
        guard totalEntries > 0 else {
            return 0
        }
        return min(max(Double(processedEntries) / Double(totalEntries), 0), 1)
    }
}

public struct DictionaryImportService: Sendable {
    public static let supportedSchemaVersion = 1
    private static let defaultInsertBatchSize = 200

    private let reader: DictionaryJSONLReader
    private let encoder: JSONEncoder

    public init(
        reader: DictionaryJSONLReader = DictionaryJSONLReader(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.reader = reader
        if #available(iOS 11.0, macOS 10.13, *) {
            encoder.outputFormatting.insert(.sortedKeys)
        }
        self.encoder = encoder
    }

    public func importBundle(manifest: DictionaryManifest, entriesData: Data) throws -> DictionaryBundle {
        try validateSchemaVersion(manifest)

        var entries: [DictionaryEntry] = []
        let stats = try reader.enumerateEntriesAndCollect(from: entriesData) { entry in
            entries.append(entry)
        }
        try validateCounts(manifest: manifest, stats: stats)

        return DictionaryBundle(
            entryCount: manifest.entryCount,
            senseCount: manifest.senseCount,
            exampleCount: manifest.exampleCount,
            entries: entries
        )
    }

    public func importDatabase(
        manifest: DictionaryManifest,
        entriesData: Data,
        databaseURL: URL,
        onProgress: ((DictionaryImportProgress) -> Void)? = nil
    ) throws -> DictionaryBundle {
        try validateSchemaVersion(manifest)
        let stats = try writeDatabaseStreaming(
            manifest: manifest,
            entriesData: entriesData,
            databaseURL: databaseURL,
            onProgress: onProgress
        )
        return DictionaryBundle(
            entryCount: stats.entryCount,
            senseCount: stats.senseCount,
            exampleCount: stats.exampleCount,
            entries: [],
            databasePath: databaseURL.path
        )
    }

    private func writeDatabaseStreaming(
        manifest: DictionaryManifest,
        entriesData: Data,
        databaseURL: URL,
        onProgress: ((DictionaryImportProgress) -> Void)?
    ) throws -> ImportStats {
        let parentDirectory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            try FileManager.default.removeItem(at: databaseURL)
        }

        let dbQueue = try DictionaryDatabase.openQueue(at: databaseURL)
        try DictionaryDatabase.migrate(dbQueue)

        var stats = ImportStats()
        onProgress?(DictionaryImportProgress(processedEntries: 0, totalEntries: manifest.entryCount))

        try dbQueue.writeWithoutTransaction { db in
            try db.execute(sql: "BEGIN IMMEDIATE")
            var insertsInTransaction = 0

            do {
                try reader.enumerateEntries(from: entriesData) { entry in
                    try insertEntry(entry, into: db)
                    stats.record(entry)
                    insertsInTransaction += 1

                    if insertsInTransaction >= Self.defaultInsertBatchSize {
                        try db.execute(sql: "COMMIT")
                        onProgress?(DictionaryImportProgress(
                            processedEntries: stats.entryCount,
                            totalEntries: manifest.entryCount
                        ))
                        try db.execute(sql: "BEGIN IMMEDIATE")
                        insertsInTransaction = 0
                    }
                }

                try validateCounts(manifest: manifest, stats: stats)
                try insertMetadata(for: stats, manifest: manifest, into: db)
                try db.execute(sql: "COMMIT")
                onProgress?(DictionaryImportProgress(
                    processedEntries: stats.entryCount,
                    totalEntries: manifest.entryCount
                ))
            } catch {
                try? db.execute(sql: "ROLLBACK")
                throw error
            }
        }

        return stats
    }

    private func insertEntry(_ entry: DictionaryEntry, into db: Database) throws {
        try db.execute(
            sql: """
            INSERT INTO dictionary_entries (
                id, type, hanji, romanization, category, audio_id,
                variant_chars, word_synonyms, word_antonyms,
                alternative_pronunciations, contracted_pronunciations,
                colloquial_pronunciations, phonetic_differences,
                vocabulary_comparisons, alias_target_entry_id,
                hokkien_search, mandarin_search
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            arguments: [
                entry.id,
                entry.type,
                entry.hanji,
                entry.romanization,
                entry.category,
                entry.audioID,
                try jsonString(entry.variantChars),
                try jsonString(entry.wordSynonyms),
                try jsonString(entry.wordAntonyms),
                try jsonString(entry.alternativePronunciations),
                try jsonString(entry.contractedPronunciations),
                try jsonString(entry.colloquialPronunciations),
                try jsonString(entry.phoneticDifferences),
                try jsonString(entry.vocabularyComparisons),
                entry.aliasTargetEntryID,
                entry.hokkienSearch,
                entry.mandarinSearch,
            ]
        )

        for (senseOffset, sense) in entry.senses.enumerated() {
            let senseID = Int64(senseOffset + 1)
            try db.execute(
                sql: """
                INSERT INTO dictionary_senses (
                    entry_id, sense_id, part_of_speech, definition,
                    definition_synonyms, definition_antonyms
                ) VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    entry.id,
                    senseID,
                    sense.partOfSpeech,
                    sense.definition,
                    try jsonString(sense.definitionSynonyms),
                    try jsonString(sense.definitionAntonyms),
                ]
            )

            for (exampleOffset, example) in sense.examples.enumerated() {
                try db.execute(
                    sql: """
                    INSERT INTO dictionary_examples (
                        entry_id, sense_id, example_order, hanji,
                        romanization, mandarin, audio_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        entry.id,
                        senseID,
                        exampleOffset,
                        example.hanji,
                        example.romanization,
                        example.mandarin,
                        example.audioID,
                    ]
                )
            }
        }
    }

    private func insertMetadata(
        for stats: ImportStats,
        manifest: DictionaryManifest,
        into db: Database
    ) throws {
        let items: [(String, String)] = [
            ("built_at", manifest.builtAt),
            ("source_modified_at", manifest.sourceModifiedAt ?? ""),
            ("entry_count", String(stats.entryCount)),
            ("sense_count", String(stats.senseCount)),
            ("example_count", String(stats.exampleCount)),
        ]

        for (key, value) in items {
            try db.execute(
                sql: "INSERT INTO dictionary_metadata (key, value) VALUES (?, ?)",
                arguments: [key, value]
            )
        }
    }

    private func jsonString(_ values: [String]) throws -> String {
        let data = try encoder.encode(values)
        return String(decoding: data, as: UTF8.self)
    }

    private func validateSchemaVersion(_ manifest: DictionaryManifest) throws {
        guard manifest.schemaVersion == Self.supportedSchemaVersion else {
            throw DictionaryImportError.unsupportedSchemaVersion(manifest.schemaVersion)
        }
    }

    private func validateCounts(manifest: DictionaryManifest, stats: ImportStats) throws {
        guard stats.entryCount == manifest.entryCount else {
            throw DictionaryImportError.entryCountMismatch(
                expected: manifest.entryCount,
                actual: stats.entryCount
            )
        }

        guard stats.senseCount == manifest.senseCount else {
            throw DictionaryImportError.senseCountMismatch(
                expected: manifest.senseCount,
                actual: stats.senseCount
            )
        }

        guard stats.exampleCount == manifest.exampleCount else {
            throw DictionaryImportError.exampleCountMismatch(
                expected: manifest.exampleCount,
                actual: stats.exampleCount
            )
        }
    }
}

private struct ImportStats {
    var entryCount = 0
    var senseCount = 0
    var exampleCount = 0

    mutating func record(_ entry: DictionaryEntry) {
        entryCount += 1
        senseCount += entry.senses.count
        exampleCount += entry.senses.reduce(0) { $0 + $1.examples.count }
    }
}

private extension DictionaryJSONLReader {
    func enumerateEntriesAndCollect(
        from data: Data,
        onEntry: (DictionaryEntry) throws -> Void
    ) throws -> ImportStats {
        var stats = ImportStats()
        try enumerateEntries(from: data) { entry in
            stats.record(entry)
            try onEntry(entry)
        }
        return stats
    }
}
