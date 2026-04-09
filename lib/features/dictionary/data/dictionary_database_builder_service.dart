import 'dart:io';

import 'package:hokkien_dictionary/core/constants/app_constants.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_search_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryDatabaseBuildResult {
  const DictionaryDatabaseBuildResult({
    required this.entryCount,
    required this.senseCount,
    required this.exampleCount,
  });

  final int entryCount;
  final int senseCount;
  final int exampleCount;
}

class DictionaryDatabaseBuilderService {
  const DictionaryDatabaseBuilderService();

  static const _entriesTable = 'dictionary_entries';
  static const _sensesTable = 'dictionary_senses';
  static const _examplesTable = 'dictionary_examples';
  static const _metadataTable = 'dictionary_metadata';

  Future<File> locateDownloadedOdsFile() async {
    final directory = await _dictionaryRootDirectory();
    return File(path.join(directory.path, AppConstants.dictionaryOdsFileName));
  }

  Future<File> locateDatabaseFile() async {
    final directory = await _dictionaryRootDirectory();
    return File(
      path.join(directory.path, AppConstants.dictionaryDatabaseFileName),
    );
  }

  Future<bool> hasDownloadedOdsFile() async {
    return (await locateDownloadedOdsFile()).exists();
  }

  Future<bool> hasBuiltDatabase() async {
    return (await locateDatabaseFile()).exists();
  }

  Future<bool> needsRebuild() async {
    final odsFile = await locateDownloadedOdsFile();
    if (!await odsFile.exists()) {
      return false;
    }

    final databaseFile = await locateDatabaseFile();
    if (!await databaseFile.exists()) {
      return true;
    }

    final odsStat = await odsFile.stat();
    final databaseStat = await databaseFile.stat();
    return odsStat.modified.isAfter(databaseStat.modified);
  }

  Future<DictionaryDatabaseBuildResult> rebuildFromDownloadedOds() async {
    final odsFile = await locateDownloadedOdsFile();
    if (!await odsFile.exists()) {
      throw FileSystemException('找不到已下載的 kautian.ods', odsFile.path);
    }

    final databaseFile = await locateDatabaseFile();
    await databaseFile.parent.create(recursive: true);

    final workbook = SpreadsheetDecoder.decodeBytes(
      await odsFile.readAsBytes(),
    );
    final headwordRows = _recordsForSheet(workbook, '詞目');
    final senseRows = _recordsForSheet(workbook, '義項');
    final exampleRows = _recordsForSheet(workbook, '例句');

    final entryRowsById = <int, _EntrySeed>{};
    for (final row in headwordRows) {
      final headwordId = _parseInt(row['詞目id']);
      if (headwordId == null) {
        continue;
      }
      entryRowsById[headwordId] = _EntrySeed(
        id: headwordId,
        type: row['詞目類型'] ?? '',
        hanji: row['漢字'] ?? '',
        romanization: row['羅馬字'] ?? '',
        category: row['分類'] ?? '',
        audioId: row['羅馬字音檔檔名'] ?? '',
      );
    }

    final senseRowsByKey = <(int, int), _SenseSeed>{};
    for (final row in senseRows) {
      final headwordId = _parseInt(row['詞目id']);
      final senseId = _parseInt(row['義項id']);
      if (headwordId == null || senseId == null) {
        continue;
      }

      final entry = entryRowsById[headwordId];
      if (entry == null) {
        continue;
      }

      final sense = _SenseSeed(
        entryId: headwordId,
        senseId: senseId,
        partOfSpeech: row['詞性'] ?? '',
        definition: row['解說'] ?? '',
      );
      entry.senses.add(sense);
      senseRowsByKey[(headwordId, senseId)] = sense;
    }

    var exampleCount = 0;
    for (final row in exampleRows) {
      final headwordId = _parseInt(row['詞目id']);
      final senseId = _parseInt(row['義項id']);
      if (headwordId == null || senseId == null) {
        continue;
      }

      final sense = senseRowsByKey[(headwordId, senseId)];
      if (sense == null) {
        continue;
      }

      sense.examples.add(
        _ExampleSeed(
          order: _parseInt(row['例句順序']) ?? 0,
          hanji: row['漢字'] ?? '',
          romanization: row['羅馬字'] ?? '',
          mandarin: row['華語'] ?? '',
          audioId: row['音檔檔名'] ?? '',
        ),
      );
      exampleCount++;
    }

    final entries = entryRowsById.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    for (final entry in entries) {
      final mandarinSegments = <String>[];
      for (final sense in entry.senses) {
        if (sense.definition.isNotEmpty) {
          mandarinSegments.add(sense.definition);
        }
        for (final example in sense.examples) {
          if (example.mandarin.isNotEmpty) {
            mandarinSegments.add(example.mandarin);
          }
        }
      }

      final hokkienSegments = [entry.hanji, entry.romanization, entry.category];
      entry.hokkienSearch = _normalizeForSearch(hokkienSegments.join(' '));
      entry.mandarinSearch = _normalizeForSearch(mandarinSegments.join(' '));
    }

    final database = await openDatabase(
      databaseFile.path,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _dropSchema(db);
        await _createSchema(db);
      },
    );

    try {
      await database.transaction((txn) async {
        await _clearExistingData(txn);
        final batch = txn.batch();

        for (final entry in entries) {
          batch.insert(_entriesTable, <String, Object?>{
            'id': entry.id,
            'type': entry.type,
            'hanji': entry.hanji,
            'romanization': entry.romanization,
            'category': entry.category,
            'audio_id': entry.audioId,
            'hokkien_search': entry.hokkienSearch,
            'mandarin_search': entry.mandarinSearch,
          });

          for (final sense in entry.senses) {
            batch.insert(_sensesTable, <String, Object?>{
              'entry_id': entry.id,
              'sense_id': sense.senseId,
              'part_of_speech': sense.partOfSpeech,
              'definition': sense.definition,
            });

            for (final example in sense.examples) {
              batch.insert(_examplesTable, <String, Object?>{
                'entry_id': entry.id,
                'sense_id': sense.senseId,
                'example_order': example.order,
                'hanji': example.hanji,
                'romanization': example.romanization,
                'mandarin': example.mandarin,
                'audio_id': example.audioId,
              });
            }
          }
        }

        final builtAt = DateTime.now().toUtc().toIso8601String();
        final sourceModifiedAt = (await odsFile.stat()).modified
            .toUtc()
            .toIso8601String();
        batch.insert(_metadataTable, {'key': 'built_at', 'value': builtAt});
        batch.insert(_metadataTable, {
          'key': 'source_modified_at',
          'value': sourceModifiedAt,
        });
        batch.insert(_metadataTable, {
          'key': 'entry_count',
          'value': entries.length.toString(),
        });
        batch.insert(_metadataTable, {
          'key': 'sense_count',
          'value': entries
              .fold<int>(0, (sum, entry) => sum + entry.senses.length)
              .toString(),
        });
        batch.insert(_metadataTable, {
          'key': 'example_count',
          'value': exampleCount.toString(),
        });

        await batch.commit(noResult: true);
      });
    } finally {
      await database.close();
    }

    return DictionaryDatabaseBuildResult(
      entryCount: entries.length,
      senseCount: entries.fold<int>(
        0,
        (sum, entry) => sum + entry.senses.length,
      ),
      exampleCount: exampleCount,
    );
  }

  Future<DictionaryBundle?> loadBundleIfAvailable() async {
    final databaseFile = await locateDatabaseFile();
    if (!await databaseFile.exists()) {
      return null;
    }

    final database = await openDatabase(databaseFile.path, readOnly: true);
    try {
      final entryRows = await database.query(_entriesTable, orderBy: 'id ASC');
      if (entryRows.isEmpty) {
        return null;
      }

      final senseRows = await database.query(
        _sensesTable,
        orderBy: 'entry_id ASC, sense_id ASC',
      );
      final exampleRows = await database.query(
        _examplesTable,
        orderBy: 'entry_id ASC, sense_id ASC, example_order ASC, id ASC',
      );

      final examplesBySense = <(int, int), List<DictionaryExample>>{};
      for (final row in exampleRows) {
        final entryId = row['entry_id'] as int;
        final senseId = row['sense_id'] as int;
        examplesBySense
            .putIfAbsent((entryId, senseId), () => [])
            .add(
              DictionaryExample(
                hanji: row['hanji'] as String? ?? '',
                romanization: row['romanization'] as String? ?? '',
                mandarin: row['mandarin'] as String? ?? '',
                audioId: row['audio_id'] as String? ?? '',
              ),
            );
      }

      final sensesByEntry = <int, List<DictionarySense>>{};
      for (final row in senseRows) {
        final entryId = row['entry_id'] as int;
        final senseId = row['sense_id'] as int;
        sensesByEntry
            .putIfAbsent(entryId, () => [])
            .add(
              DictionarySense(
                partOfSpeech: row['part_of_speech'] as String? ?? '',
                definition: row['definition'] as String? ?? '',
                examples: examplesBySense[(entryId, senseId)] ?? const [],
              ),
            );
      }

      final entries = entryRows
          .map(
            (row) => DictionaryEntry(
              id: row['id'] as int,
              type: row['type'] as String? ?? '',
              hanji: row['hanji'] as String? ?? '',
              romanization: row['romanization'] as String? ?? '',
              category: row['category'] as String? ?? '',
              audioId: row['audio_id'] as String? ?? '',
              hokkienSearch: row['hokkien_search'] as String? ?? '',
              mandarinSearch: row['mandarin_search'] as String? ?? '',
              senses: sensesByEntry[row['id'] as int] ?? const [],
            ),
          )
          .toList(growable: false);

      return DictionaryBundle(
        entryCount: entries.length,
        senseCount: senseRows.length,
        exampleCount: exampleRows.length,
        entries: entries,
      );
    } finally {
      await database.close();
    }
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_entriesTable (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        hanji TEXT NOT NULL,
        romanization TEXT NOT NULL,
        category TEXT NOT NULL,
        audio_id TEXT NOT NULL,
        hokkien_search TEXT NOT NULL,
        mandarin_search TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sensesTable (
        entry_id INTEGER NOT NULL,
        sense_id INTEGER NOT NULL,
        part_of_speech TEXT NOT NULL,
        definition TEXT NOT NULL,
        PRIMARY KEY (entry_id, sense_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_examplesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER NOT NULL,
        sense_id INTEGER NOT NULL,
        example_order INTEGER NOT NULL,
        hanji TEXT NOT NULL,
        romanization TEXT NOT NULL,
        mandarin TEXT NOT NULL,
        audio_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_hokkien_search ON $_entriesTable(hokkien_search)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_mandarin_search ON $_entriesTable(mandarin_search)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_senses_entry_id ON $_sensesTable(entry_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_examples_entry_sense_order ON $_examplesTable(entry_id, sense_id, example_order)',
    );
  }

  Future<void> _dropSchema(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS $_metadataTable');
    await db.execute('DROP TABLE IF EXISTS $_examplesTable');
    await db.execute('DROP TABLE IF EXISTS $_sensesTable');
    await db.execute('DROP TABLE IF EXISTS $_entriesTable');
  }

  Future<void> _clearExistingData(DatabaseExecutor db) async {
    await db.delete(_metadataTable);
    await db.delete(_examplesTable);
    await db.delete(_sensesTable);
    await db.delete(_entriesTable);
  }

  List<Map<String, String>> _recordsForSheet(
    SpreadsheetDecoder workbook,
    String sheetName,
  ) {
    final table = workbook.tables[sheetName];
    if (table == null) {
      throw FormatException('ODS 內找不到工作表：$sheetName');
    }

    final rows = table.rows;
    if (rows.isEmpty) {
      return const [];
    }

    final headers = rows.first.map(_cellToString).toList(growable: false);
    final records = <Map<String, String>>[];

    for (final row in rows.skip(1)) {
      final values = List<String>.generate(headers.length, (index) {
        if (index >= row.length) {
          return '';
        }
        return _cellToString(row[index]);
      }, growable: false);
      if (values.every((value) => value.isEmpty)) {
        continue;
      }
      records.add(<String, String>{
        for (var index = 0; index < headers.length; index++)
          headers[index]: values[index].trim(),
      });
    }

    return records;
  }

  Future<Directory> _dictionaryRootDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(
      path.join(
        supportDirectory.path,
        AppConstants.offlineDictionaryDirectoryName,
      ),
    );
  }

  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return int.tryParse(value) ??
        int.tryParse(double.parse(value).toInt().toString());
  }

  String _cellToString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _normalizeForSearch(String text) {
    return normalizeQuery(text);
  }
}

class _EntrySeed {
  _EntrySeed({
    required this.id,
    required this.type,
    required this.hanji,
    required this.romanization,
    required this.category,
    required this.audioId,
  });

  final int id;
  final String type;
  final String hanji;
  final String romanization;
  final String category;
  final String audioId;
  String hokkienSearch = '';
  String mandarinSearch = '';
  final List<_SenseSeed> senses = <_SenseSeed>[];
}

class _SenseSeed {
  _SenseSeed({
    required this.entryId,
    required this.senseId,
    required this.partOfSpeech,
    required this.definition,
  });

  final int entryId;
  final int senseId;
  final String partOfSpeech;
  final String definition;
  final List<_ExampleSeed> examples = <_ExampleSeed>[];
}

class _ExampleSeed {
  _ExampleSeed({
    required this.order,
    required this.hanji,
    required this.romanization,
    required this.mandarin,
    required this.audioId,
  });

  final int order;
  final String hanji;
  final String romanization;
  final String mandarin;
  final String audioId;
}
