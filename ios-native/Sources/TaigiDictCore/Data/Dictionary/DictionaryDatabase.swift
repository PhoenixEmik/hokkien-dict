import Foundation
import GRDB

enum DictionaryDatabase {
    static func openQueue(at databaseURL: URL, readonly: Bool = false) throws -> DatabaseQueue {
        var configuration = Configuration()
        configuration.readonly = readonly
        return try DatabaseQueue(path: databaseURL.path, configuration: configuration)
    }

    static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_create_dictionary_schema") { db in
            try db.execute(sql: schemaSQL)
        }
        try migrator.migrate(dbQueue)
    }

    private static let schemaSQL = """
    CREATE TABLE dictionary_entries (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        hanji TEXT NOT NULL,
        romanization TEXT NOT NULL,
        category TEXT NOT NULL,
        audio_id TEXT NOT NULL,
        variant_chars TEXT NOT NULL,
        word_synonyms TEXT NOT NULL,
        word_antonyms TEXT NOT NULL,
        alternative_pronunciations TEXT NOT NULL,
        contracted_pronunciations TEXT NOT NULL,
        colloquial_pronunciations TEXT NOT NULL,
        phonetic_differences TEXT NOT NULL,
        vocabulary_comparisons TEXT NOT NULL,
        alias_target_entry_id INTEGER,
        hokkien_search TEXT NOT NULL,
        mandarin_search TEXT NOT NULL
    );
    CREATE TABLE dictionary_senses (
        entry_id INTEGER NOT NULL,
        sense_id INTEGER NOT NULL,
        part_of_speech TEXT NOT NULL,
        definition TEXT NOT NULL,
        definition_synonyms TEXT NOT NULL,
        definition_antonyms TEXT NOT NULL,
        PRIMARY KEY (entry_id, sense_id)
    );
    CREATE TABLE dictionary_examples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER NOT NULL,
        sense_id INTEGER NOT NULL,
        example_order INTEGER NOT NULL,
        hanji TEXT NOT NULL,
        romanization TEXT NOT NULL,
        mandarin TEXT NOT NULL,
        audio_id TEXT NOT NULL
    );
    CREATE TABLE dictionary_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
    );
    CREATE INDEX idx_entries_hokkien_search ON dictionary_entries(hokkien_search);
    CREATE INDEX idx_entries_mandarin_search ON dictionary_entries(mandarin_search);
    CREATE INDEX idx_senses_entry_id ON dictionary_senses(entry_id);
    CREATE INDEX idx_examples_entry_sense_order ON dictionary_examples(entry_id, sense_id, example_order);
    """
}