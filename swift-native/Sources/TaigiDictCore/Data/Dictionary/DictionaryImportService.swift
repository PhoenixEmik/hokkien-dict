import Foundation
import GRDB

public enum DictionaryImportError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case entryCountMismatch(expected: Int, actual: Int)
    case senseCountMismatch(expected: Int, actual: Int)
    case exampleCountMismatch(expected: Int, actual: Int)
}

public struct DictionaryImportService: Sendable {
    public static let supportedSchemaVersion = 1

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
        guard manifest.schemaVersion == Self.supportedSchemaVersion else {
            throw DictionaryImportError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        let entries = try reader.readEntries(from: entriesData)
        let senseCount = entries.reduce(0) { $0 + $1.senses.count }
        let exampleCount = entries.reduce(0) { partial, entry in
            partial + entry.senses.reduce(0) { $0 + $1.examples.count }
        }

        guard entries.count == manifest.entryCount else {
            throw DictionaryImportError.entryCountMismatch(
                expected: manifest.entryCount,
                actual: entries.count
            )
        }

        guard senseCount == manifest.senseCount else {
            throw DictionaryImportError.senseCountMismatch(
                expected: manifest.senseCount,
                actual: senseCount
            )
        }

        guard exampleCount == manifest.exampleCount else {
            throw DictionaryImportError.exampleCountMismatch(
                expected: manifest.exampleCount,
                actual: exampleCount
            )
        }

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
        databaseURL: URL
    ) throws -> DictionaryBundle {
        let bundle = try importBundle(manifest: manifest, entriesData: entriesData)
        try writeDatabase(bundle: bundle, manifest: manifest, databaseURL: databaseURL)
        return DictionaryBundle(
            entryCount: bundle.entryCount,
            senseCount: bundle.senseCount,
            exampleCount: bundle.exampleCount,
            entries: [],
            databasePath: databaseURL.path
        )
    }

    private func writeDatabase(
        bundle: DictionaryBundle,
        manifest: DictionaryManifest,
        databaseURL: URL
    ) throws {
        let parentDirectory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: databaseURL.path) {
            try FileManager.default.removeItem(at: databaseURL)
        }

        let dbQueue = try DictionaryDatabase.openQueue(at: databaseURL)
        try DictionaryDatabase.migrate(dbQueue)
        try dbQueue.write { db in
            try insertEntries(bundle.entries, into: db)
            try insertMetadata(for: bundle, manifest: manifest, into: db)
        }
    }

    private func insertEntries(_ entries: [DictionaryEntry], into db: Database) throws {
        for entry in entries {
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
    }

    private func insertMetadata(
        for bundle: DictionaryBundle,
        manifest: DictionaryManifest,
        into db: Database
    ) throws {
        let items: [(String, String)] = [
            ("built_at", manifest.builtAt),
            ("source_modified_at", manifest.sourceModifiedAt ?? ""),
            ("entry_count", String(bundle.entryCount)),
            ("sense_count", String(bundle.senseCount)),
            ("example_count", String(bundle.exampleCount)),
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
}
