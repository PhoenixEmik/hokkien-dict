import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';


const _entriesTable = 'dictionary_entries';
const _sensesTable = 'dictionary_senses';
const _examplesTable = 'dictionary_examples';
const _metadataTable = 'dictionary_metadata';
const _buildChunkSize = 250;
const _progressUpdateInterval = 200;
const _variantSheet = '異用字';
const _senseToSenseSynonymSheet = '義項tuì義項近義';
const _senseToSenseAntonymSheet = '義項tuì義項反義';
const _senseToWordSynonymSheet = '義項tuì詞目近義';
const _senseToWordAntonymSheet = '義項tuì詞目反義';
const _wordToWordSynonymSheet = '詞目tuì詞目近義';
const _wordToWordAntonymSheet = '詞目tuì詞目反義';
const _alternativePronunciationSheet = '又唸作';
const _contractedPronunciationSheet = '合音唸作';
const _colloquialPronunciationSheet = '俗唸作';
const _phoneticDifferencesSheet = '語音差異';
const _vocabularyComparisonSheet = '詞彙比較';
const _unlistedRelationEntryType = '近反義詞不單列詞目者';

class MissingDictionarySourceException implements Exception {
  const MissingDictionarySourceException({required this.path});

  final String path;
}

class CorruptedDictionarySourceException implements Exception {
  const CorruptedDictionarySourceException({required this.path});

  final String path;
}

class MissingDictionarySheetException implements Exception {
  const MissingDictionarySheetException({required this.sheetName});

  final String sheetName;
}

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

enum DictionaryBuildPhase {
  validatingSource,
  parsingSource,
  writingDatabase,
  finalizing,
}

class DictionaryBuildProgress {
  const DictionaryBuildProgress({
    required this.phase,
    required this.processedUnits,
    required this.totalUnits,
    this.entryCount = 0,
    this.senseCount = 0,
    this.exampleCount = 0,
  });

  final DictionaryBuildPhase phase;
  final int processedUnits;
  final int totalUnits;
  final int entryCount;
  final int senseCount;
  final int exampleCount;

  double? get progress {
    if (totalUnits <= 0) {
      return null;
    }
    return (processedUnits / totalUnits).clamp(0.0, 1.0);
  }
}

class DictionaryDatabaseBuilderService {
  const DictionaryDatabaseBuilderService();

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
    final sourceFile = await locateDownloadedOdsFile();
    return sourceFile.exists();
  }

  Future<bool> hasBuiltDatabase() async {
    final databaseFile = await locateDatabaseFile();
    if (!await databaseFile.exists()) {
      return false;
    }
    if (await databaseFile.length() <= 0) {
      return false;
    }

    final database = await _openReadOnlyDatabase(databaseFile.path);
    try {
      return await _hasRelationshipSchema(database);
    } finally {
      await database.close();
    }
  }

  Future<bool> deleteInvalidDownloadedOdsIfNeeded() async {
    final sourceFile = await locateDownloadedOdsFile();
    if (!await sourceFile.exists()) {
      return false;
    }

    final fileLength = await sourceFile.length();
    if (fileLength > 0) {
      return false;
    }

    await deleteDownloadedSourceFiles();
    return true;
  }

  Future<void> deleteDownloadedSourceFiles() async {
    final sourceFile = await locateDownloadedOdsFile();
    final tempFile = File('${sourceFile.path}.download');
    if (await sourceFile.exists()) {
      await sourceFile.delete();
    }
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  Future<bool> needsRebuild() async {
    final odsFile = await locateDownloadedOdsFile();
    if (!await odsFile.exists()) {
      return false;
    }
    if (await odsFile.length() <= 0) {
      return true;
    }

    final databaseFile = await locateDatabaseFile();
    if (!await databaseFile.exists()) {
      return true;
    }

    final database = await _openReadOnlyDatabase(databaseFile.path);
    try {
      if (!await _hasRelationshipSchema(database)) {
        return true;
      }
    } finally {
      await database.close();
    }

    final odsStat = await odsFile.stat();
    final databaseStat = await databaseFile.stat();
    return odsStat.modified.isAfter(databaseStat.modified);
  }

  Future<DictionaryDatabaseBuildResult> rebuildFromDownloadedOds({
    void Function(DictionaryBuildProgress progress)? onProgress,
  }) async {
    final odsFile = await locateDownloadedOdsFile();
    if (!await odsFile.exists()) {
      throw MissingDictionarySourceException(path: odsFile.path);
    }

    final sourceLength = await odsFile.length();
    if (sourceLength <= 0) {
      await deleteDownloadedSourceFiles();
      throw CorruptedDictionarySourceException(path: odsFile.path);
    }

    onProgress?.call(
      const DictionaryBuildProgress(
        phase: DictionaryBuildPhase.validatingSource,
        processedUnits: 0,
        totalUnits: 0,
      ),
    );

    final databaseFile = await locateDatabaseFile();
    await databaseFile.parent.create(recursive: true);

    final tempDatabaseFile = File('${databaseFile.path}.building');
    await deleteDatabase(tempDatabaseFile.path);

    final sourceModifiedAt = (await odsFile.stat()).modified
        .toUtc()
        .toIso8601String();
    final builtAt = DateTime.now().toUtc().toIso8601String();

    final database = await openDatabase(
      tempDatabaseFile.path,
      singleInstance: false,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _dropSchema(db);
        await _createSchema(db);
      },
    );

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<List<Object?>>(
      _parseDictionaryOdsIsolateEntryPoint,
      <Object?>[receivePort.sendPort, odsFile.path],
    );

    var insertedRows = 0;
    var totalInsertRows = 0;
    var entryCount = 0;
    var senseCount = 0;
    var exampleCount = 0;

    try {
      await _clearExistingData(database);

      await for (final message in receivePort) {
        if (message is! Map<Object?, Object?>) {
          continue;
        }

        final type = message['type'] as String? ?? '';
        if (type == 'progress') {
          onProgress?.call(
            DictionaryBuildProgress(
              phase: DictionaryBuildPhase.parsingSource,
              processedUnits: message['processed'] as int? ?? 0,
              totalUnits: message['total'] as int? ?? 0,
            ),
          );
          continue;
        }

        if (type == 'chunk') {
          final table = message['table'] as String? ?? '';
          final rows = (message['rows'] as List<Object?>? ?? const [])
              .cast<Map<Object?, Object?>>()
              .map(
                (row) => row.map<String, Object?>(
                  (key, value) => MapEntry(key as String, value),
                ),
              )
              .toList(growable: false);
          if (rows.isEmpty) {
            continue;
          }

          await _insertChunk(database, table: table, rows: rows);
          insertedRows += rows.length;
          onProgress?.call(
            DictionaryBuildProgress(
              phase: DictionaryBuildPhase.writingDatabase,
              processedUnits: insertedRows,
              totalUnits: totalInsertRows,
              entryCount: entryCount,
              senseCount: senseCount,
              exampleCount: exampleCount,
            ),
          );
          continue;
        }

        if (type == 'summary') {
          entryCount = message['entryCount'] as int? ?? 0;
          senseCount = message['senseCount'] as int? ?? 0;
          exampleCount = message['exampleCount'] as int? ?? 0;
          totalInsertRows = message['totalInsertRows'] as int? ?? 0;
          onProgress?.call(
            DictionaryBuildProgress(
              phase: DictionaryBuildPhase.writingDatabase,
              processedUnits: insertedRows,
              totalUnits: totalInsertRows,
              entryCount: entryCount,
              senseCount: senseCount,
              exampleCount: exampleCount,
            ),
          );
          continue;
        }

        if (type == 'done') {
          break;
        }

        if (type == 'error') {
          throw _parseIsolateError(message);
        }
      }

      onProgress?.call(
        DictionaryBuildProgress(
          phase: DictionaryBuildPhase.finalizing,
          processedUnits: totalInsertRows,
          totalUnits: totalInsertRows,
          entryCount: entryCount,
          senseCount: senseCount,
          exampleCount: exampleCount,
        ),
      );

      await _writeMetadata(
        database,
        builtAt: builtAt,
        sourceModifiedAt: sourceModifiedAt,
        entryCount: entryCount,
        senseCount: senseCount,
        exampleCount: exampleCount,
      );
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
      await database.close();
    }

    await deleteDatabase(databaseFile.path);
    await tempDatabaseFile.rename(databaseFile.path);

    return DictionaryDatabaseBuildResult(
      entryCount: entryCount,
      senseCount: senseCount,
      exampleCount: exampleCount,
    );
  }

  Future<DictionaryBundle?> loadBundleIfAvailable() async {
    final databaseFile = await locateDatabaseFile();
    if (!await databaseFile.exists()) {
      return null;
    }

    final database = await _openReadOnlyDatabase(databaseFile.path);
    try {
      if (!await _hasRelationshipSchema(database)) {
        return null;
      }

      final metadataRows = await database.query(_metadataTable);
      final metadata = {
        for (final row in metadataRows)
          row['key'] as String: row['value']?.toString() ?? '0',
      };
      final entryCount =
          int.tryParse(metadata['entry_count'] ?? '') ??
          Sqflite.firstIntValue(
            await database.rawQuery('SELECT COUNT(*) FROM $_entriesTable'),
          ) ??
          0;
      if (entryCount == 0) {
        return null;
      }
      final senseCount =
          int.tryParse(metadata['sense_count'] ?? '') ??
          Sqflite.firstIntValue(
            await database.rawQuery('SELECT COUNT(*) FROM $_sensesTable'),
          ) ??
          0;
      final exampleCount =
          int.tryParse(metadata['example_count'] ?? '') ??
          Sqflite.firstIntValue(
            await database.rawQuery('SELECT COUNT(*) FROM $_examplesTable'),
          ) ??
          0;
      return DictionaryBundle(
        entryCount: entryCount,
        senseCount: senseCount,
        exampleCount: exampleCount,
        entries: const [],
        databasePath: databaseFile.path,
      );
    } finally {
      await database.close();
    }
  }

  Future<void> _insertChunk(
    Database database, {
    required String table,
    required List<Map<String, Object?>> rows,
  }) async {
    final batch = database.batch();
    for (final row in rows) {
      batch.insert(table, row);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _writeMetadata(
    Database database, {
    required String builtAt,
    required String sourceModifiedAt,
    required int entryCount,
    required int senseCount,
    required int exampleCount,
  }) async {
    final batch = database.batch();
    batch.insert(_metadataTable, {'key': 'built_at', 'value': builtAt});
    batch.insert(_metadataTable, {
      'key': 'source_modified_at',
      'value': sourceModifiedAt,
    });
    batch.insert(_metadataTable, {
      'key': 'entry_count',
      'value': entryCount.toString(),
    });
    batch.insert(_metadataTable, {
      'key': 'sense_count',
      'value': senseCount.toString(),
    });
    batch.insert(_metadataTable, {
      'key': 'example_count',
      'value': exampleCount.toString(),
    });
    await batch.commit(noResult: true);
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
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sensesTable (
        entry_id INTEGER NOT NULL,
        sense_id INTEGER NOT NULL,
        part_of_speech TEXT NOT NULL,
        definition TEXT NOT NULL,
        definition_synonyms TEXT NOT NULL,
        definition_antonyms TEXT NOT NULL,
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

  Future<bool> _hasRelationshipSchema(DatabaseExecutor db) async {
    final entryColumns = await db.rawQuery('PRAGMA table_info($_entriesTable)');
    final senseColumns = await db.rawQuery('PRAGMA table_info($_sensesTable)');
    final entryColumnNames = entryColumns
        .map((row) => row['name']?.toString() ?? '')
        .toSet();
    final senseColumnNames = senseColumns
        .map((row) => row['name']?.toString() ?? '')
        .toSet();

    return entryColumnNames.contains('variant_chars') &&
        entryColumnNames.contains('word_synonyms') &&
        entryColumnNames.contains('word_antonyms') &&
        entryColumnNames.contains('alternative_pronunciations') &&
        entryColumnNames.contains('contracted_pronunciations') &&
        entryColumnNames.contains('colloquial_pronunciations') &&
        entryColumnNames.contains('phonetic_differences') &&
        entryColumnNames.contains('vocabulary_comparisons') &&
        entryColumnNames.contains('alias_target_entry_id') &&
        senseColumnNames.contains('definition_synonyms') &&
        senseColumnNames.contains('definition_antonyms');
  }

  Future<Directory> _dictionaryRootDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      path.join(
        documentsDirectory.path,
        AppConstants.offlineDictionaryDirectoryName,
      ),
    );
  }

  Future<Database> _openReadOnlyDatabase(String databasePath) {
    return openDatabase(databasePath, readOnly: true, singleInstance: false);
  }
}

void _parseDictionaryOdsIsolateEntryPoint(List<Object?> args) async {
  final sendPort = args[0]! as SendPort;
  final filePath = args[1]! as String;

  try {
    final odsFile = File(filePath);
    if (!await odsFile.exists()) {
      sendPort.send({
        'type': 'error',
        'errorType': 'missing_source',
        'path': filePath,
      });
      return;
    }

    final fileBytes = await odsFile.readAsBytes();
    if (fileBytes.isEmpty) {
      sendPort.send({
        'type': 'error',
        'errorType': 'corrupted_source',
        'path': filePath,
      });
      return;
    }

    final workbook = SpreadsheetDecoder.decodeBytes(fileBytes);
    final headwordTable = _requireSheet(workbook, '詞目');
    final senseTable = _requireSheet(workbook, '義項');
    final exampleTable = _requireSheet(workbook, '例句');
    final variantTable = _optionalSheet(workbook, _variantSheet);
    final senseToSenseSynonymTable = _optionalSheet(
      workbook,
      _senseToSenseSynonymSheet,
    );
    final senseToSenseAntonymTable = _optionalSheet(
      workbook,
      _senseToSenseAntonymSheet,
    );
    final senseToWordSynonymTable = _optionalSheet(
      workbook,
      _senseToWordSynonymSheet,
    );
    final senseToWordAntonymTable = _optionalSheet(
      workbook,
      _senseToWordAntonymSheet,
    );
    final wordToWordSynonymTable = _optionalSheet(
      workbook,
      _wordToWordSynonymSheet,
    );
    final wordToWordAntonymTable = _optionalSheet(
      workbook,
      _wordToWordAntonymSheet,
    );
    final alternativePronunciationTable = _optionalSheet(
      workbook,
      _alternativePronunciationSheet,
    );
    final contractedPronunciationTable = _optionalSheet(
      workbook,
      _contractedPronunciationSheet,
    );
    final colloquialPronunciationTable = _optionalSheet(
      workbook,
      _colloquialPronunciationSheet,
    );
    final phoneticDifferencesTable = _optionalSheet(
      workbook,
      _phoneticDifferencesSheet,
    );
    final vocabularyComparisonTable = _optionalSheet(
      workbook,
      _vocabularyComparisonSheet,
    );

    final totalRows =
        _dataRowCount(headwordTable) +
        _dataRowCount(senseTable) +
        _dataRowCount(exampleTable) +
        _dataRowCount(variantTable) +
        _dataRowCount(senseToSenseSynonymTable) +
        _dataRowCount(senseToSenseAntonymTable) +
        _dataRowCount(senseToWordSynonymTable) +
        _dataRowCount(senseToWordAntonymTable) +
        _dataRowCount(wordToWordSynonymTable) +
        _dataRowCount(wordToWordAntonymTable) +
        _dataRowCount(alternativePronunciationTable) +
        _dataRowCount(contractedPronunciationTable) +
        _dataRowCount(colloquialPronunciationTable) +
        _dataRowCount(phoneticDifferencesTable) +
        _dataRowCount(vocabularyComparisonTable);

    final headwordHeaders = _headersForRows(headwordTable.rows);
    final senseHeaders = _headersForRows(senseTable.rows);
    final exampleHeaders = _headersForRows(exampleTable.rows);
    final variantHeaders = _headersForRows(variantTable.rows);
    final senseToSenseSynonymHeaders = _headersForRows(
      senseToSenseSynonymTable.rows,
    );
    final senseToSenseAntonymHeaders = _headersForRows(
      senseToSenseAntonymTable.rows,
    );
    final senseToWordSynonymHeaders = _headersForRows(
      senseToWordSynonymTable.rows,
    );
    final senseToWordAntonymHeaders = _headersForRows(
      senseToWordAntonymTable.rows,
    );
    final wordToWordSynonymHeaders = _headersForRows(
      wordToWordSynonymTable.rows,
    );
    final wordToWordAntonymHeaders = _headersForRows(
      wordToWordAntonymTable.rows,
    );
    final alternativePronunciationHeaders = _headersForRows(
      alternativePronunciationTable.rows,
    );
    final contractedPronunciationHeaders = _headersForRows(
      contractedPronunciationTable.rows,
    );
    final colloquialPronunciationHeaders = _headersForRows(
      colloquialPronunciationTable.rows,
    );
    final phoneticDifferencesHeaders = _headersForRows(
      phoneticDifferencesTable.rows,
    );
    final vocabularyComparisonHeaders = _headersForRows(
      vocabularyComparisonTable.rows,
    );

    var processedRows = 0;
    final entryRowsById = <int, Map<String, Object?>>{};
    final mandarinByEntryId = <int, StringBuffer>{};
    final variantCharsByEntryId = <int, List<String>>{};
    final wordSynonymsByEntryId = <int, List<String>>{};
    final wordAntonymsByEntryId = <int, List<String>>{};
    final alternativePronunciationsByEntryId = <int, List<String>>{};
    final contractedPronunciationsByEntryId = <int, List<String>>{};
    final colloquialPronunciationsByEntryId = <int, List<String>>{};
    final phoneticDifferencesByEntryId = <int, List<String>>{};
    final vocabularyComparisonsByEntryId = <int, List<String>>{};
    final definitionSynonymsBySenseId = <int, List<String>>{};
    final definitionAntonymsBySenseId = <int, List<String>>{};
    final aliasTargetByEntryId = <int, int>{};
    final entryIdBySenseId = <int, int>{};
    final entryIdsByHanji = <String, Set<int>>{};

    void sendProgress() {
      sendPort.send({
        'type': 'progress',
        'processed': processedRows,
        'total': totalRows,
      });
    }

    for (final row in headwordTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(headwordHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final headwordId = _parseInt(record['詞目id']);
      if (headwordId != null) {
        entryRowsById[headwordId] = <String, Object?>{
          'id': headwordId,
          'type': record['詞目類型'] ?? '',
          'hanji': record['漢字'] ?? '',
          'romanization': record['羅馬字'] ?? '',
          'category': record['分類'] ?? '',
          'audio_id': record['羅馬字音檔檔名'] ?? '',
          'variant_chars': '[]',
          'word_synonyms': '[]',
          'word_antonyms': '[]',
          'alternative_pronunciations': '[]',
          'contracted_pronunciations': '[]',
          'colloquial_pronunciations': '[]',
          'phonetic_differences': '[]',
          'vocabulary_comparisons': '[]',
          'alias_target_entry_id': null,
        };
        final hanji = record['漢字'] ?? '';
        if (hanji.isNotEmpty) {
          entryIdsByHanji.putIfAbsent(hanji, () => <int>{}).add(headwordId);
        }
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }

    final knownSenseKeys = <String>{};
    final senseRowsByKey = <String, Map<String, Object?>>{};
    var senseCount = 0;
    for (final row in senseTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(senseHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final headwordId = _parseInt(record['詞目id']);
      final senseId = _parseInt(record['義項id']);
      if (headwordId != null &&
          senseId != null &&
          entryRowsById.containsKey(headwordId)) {
        entryIdBySenseId[senseId] = headwordId;
        final definition = record['解說'] ?? '';
        final partOfSpeech = record['詞性'] ?? '';
        final senseKey = '$headwordId:$senseId';
        senseRowsByKey[senseKey] = <String, Object?>{
          'entry_id': headwordId,
          'sense_id': senseId,
          'part_of_speech': partOfSpeech,
          'definition': definition,
          'definition_synonyms': '[]',
          'definition_antonyms': '[]',
        };
        if (definition.isNotEmpty) {
          mandarinByEntryId
              .putIfAbsent(headwordId, StringBuffer.new)
              .write('$definition ');
        }
        knownSenseKeys.add(senseKey);
        senseCount++;
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }
    final exampleChunk = <Map<String, Object?>>[];
    var exampleCount = 0;
    for (final row in exampleTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(exampleHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final headwordId = _parseInt(record['詞目id']);
      final senseId = _parseInt(record['義項id']);
      if (headwordId != null &&
          senseId != null &&
          knownSenseKeys.contains('$headwordId:$senseId')) {
        final mandarin = record['華語'] ?? '';
        exampleChunk.add(<String, Object?>{
          'entry_id': headwordId,
          'sense_id': senseId,
          'example_order': _parseInt(record['例句順序']) ?? 0,
          'hanji': record['漢字'] ?? '',
          'romanization': record['羅馬字'] ?? '',
          'mandarin': mandarin,
          'audio_id': record['音檔檔名'] ?? '',
        });
        if (mandarin.isNotEmpty) {
          mandarinByEntryId
              .putIfAbsent(headwordId, StringBuffer.new)
              .write('$mandarin ');
        }
        exampleCount++;
        if (exampleChunk.length >= _buildChunkSize) {
          sendPort.send({
            'type': 'chunk',
            'table': _examplesTable,
            'rows': List<Map<String, Object?>>.from(exampleChunk),
          });
          exampleChunk.clear();
        }
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }
    if (exampleChunk.isNotEmpty) {
      sendPort.send({
        'type': 'chunk',
        'table': _examplesTable,
        'rows': List<Map<String, Object?>>.from(exampleChunk),
      });
    }

    for (final row in variantTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(variantHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final headwordId = _parseInt(record['詞目id']);
      final variant = record['異用字'] ?? '';
      if (headwordId != null &&
          variant.isNotEmpty &&
          entryRowsById.containsKey(headwordId)) {
        _appendUniqueValue(variantCharsByEntryId, headwordId, variant);
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }

    bool isUnlistedRelationEntry(int entryId) {
      return entryRowsById[entryId]?['type'] == _unlistedRelationEntryType;
    }

    void registerAliasTarget(int sourceEntryId, int targetEntryId) {
      if (sourceEntryId == targetEntryId ||
          !entryRowsById.containsKey(sourceEntryId) ||
          !entryRowsById.containsKey(targetEntryId)) {
        return;
      }

      final sourceIsAlias = isUnlistedRelationEntry(sourceEntryId);
      final targetIsAlias = isUnlistedRelationEntry(targetEntryId);
      if (sourceIsAlias == targetIsAlias) {
        return;
      }

      final aliasEntryId = sourceIsAlias ? sourceEntryId : targetEntryId;
      final primaryEntryId = sourceIsAlias ? targetEntryId : sourceEntryId;
      aliasTargetByEntryId.putIfAbsent(aliasEntryId, () => primaryEntryId);
    }

    void collectSenseLinks({
      required SpreadsheetTable table,
      required List<String> headers,
      required Map<int, List<String>> target,
      required String targetWordColumn,
    }) {
      for (final row in table.rows.skip(1)) {
        processedRows++;
        final record = _recordForRow(headers, row);
        if (record.isEmpty) {
          if (processedRows % _progressUpdateInterval == 0) {
            sendProgress();
          }
          continue;
        }

        final senseId = _parseInt(record['義項id']);
        final linkedWord = record[targetWordColumn] ?? '';
        final sourceEntryId = senseId == null
            ? null
            : entryIdBySenseId[senseId];
        final targetEntryId =
            _parseInt(record['對應詞目id']) ??
            entryIdBySenseId[_parseInt(record['對應義項id'])];
        if (senseId != null &&
            linkedWord.isNotEmpty &&
            entryIdBySenseId.containsKey(senseId)) {
          _appendUniqueValue(target, senseId, linkedWord);
        }
        if (sourceEntryId != null && targetEntryId != null) {
          registerAliasTarget(sourceEntryId, targetEntryId);
        }

        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
      }
    }

    void collectWordLinks({
      required SpreadsheetTable table,
      required List<String> headers,
      required Map<int, List<String>> target,
    }) {
      for (final row in table.rows.skip(1)) {
        processedRows++;
        final record = _recordForRow(headers, row);
        if (record.isEmpty) {
          if (processedRows % _progressUpdateInterval == 0) {
            sendProgress();
          }
          continue;
        }

        final entryId = _parseInt(record['詞目id']);
        final targetEntryId = _parseInt(record['對應詞目id']);
        final linkedWord = record['對應詞目漢字'] ?? '';
        if (entryId != null &&
            linkedWord.isNotEmpty &&
            entryRowsById.containsKey(entryId)) {
          _appendUniqueValue(target, entryId, linkedWord);
        }
        if (entryId != null && targetEntryId != null) {
          registerAliasTarget(entryId, targetEntryId);
        }

        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
      }
    }

    collectSenseLinks(
      table: senseToSenseSynonymTable,
      headers: senseToSenseSynonymHeaders,
      target: definitionSynonymsBySenseId,
      targetWordColumn: '對應詞目漢字',
    );
    collectSenseLinks(
      table: senseToWordSynonymTable,
      headers: senseToWordSynonymHeaders,
      target: definitionSynonymsBySenseId,
      targetWordColumn: '對應詞目漢字',
    );
    collectSenseLinks(
      table: senseToSenseAntonymTable,
      headers: senseToSenseAntonymHeaders,
      target: definitionAntonymsBySenseId,
      targetWordColumn: '對應詞目漢字',
    );
    collectSenseLinks(
      table: senseToWordAntonymTable,
      headers: senseToWordAntonymHeaders,
      target: definitionAntonymsBySenseId,
      targetWordColumn: '對應詞目漢字',
    );
    collectWordLinks(
      table: wordToWordSynonymTable,
      headers: wordToWordSynonymHeaders,
      target: wordSynonymsByEntryId,
    );
    collectWordLinks(
      table: wordToWordAntonymTable,
      headers: wordToWordAntonymHeaders,
      target: wordAntonymsByEntryId,
    );

    void collectPronunciations({
      required SpreadsheetTable table,
      required List<String> headers,
      required Map<int, List<String>> target,
    }) {
      for (final row in table.rows.skip(1)) {
        processedRows++;
        final record = _recordForRow(headers, row);
        if (record.isEmpty) {
          if (processedRows % _progressUpdateInterval == 0) {
            sendProgress();
          }
          continue;
        }

        final entryId = _parseInt(record['詞目id']);
        final romanization = record['羅馬字'] ?? '';
        if (entryId != null &&
            romanization.isNotEmpty &&
            entryRowsById.containsKey(entryId)) {
          for (final value in _splitSlashSeparatedValues(romanization)) {
            _appendUniqueValue(target, entryId, value);
          }
        }

        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
      }
    }

    collectPronunciations(
      table: alternativePronunciationTable,
      headers: alternativePronunciationHeaders,
      target: alternativePronunciationsByEntryId,
    );
    collectPronunciations(
      table: contractedPronunciationTable,
      headers: contractedPronunciationHeaders,
      target: contractedPronunciationsByEntryId,
    );
    collectPronunciations(
      table: colloquialPronunciationTable,
      headers: colloquialPronunciationHeaders,
      target: colloquialPronunciationsByEntryId,
    );

    for (final row in phoneticDifferencesTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(phoneticDifferencesHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final entryId = _parseInt(record['詞目id']);
      if (entryId != null && entryRowsById.containsKey(entryId)) {
        final notes = <String>[];
        for (final header in phoneticDifferencesHeaders.skip(2)) {
          final value = record[header] ?? '';
          if (header.isNotEmpty && value.isNotEmpty) {
            notes.add('$header：$value');
          }
        }
        if (notes.isNotEmpty) {
          phoneticDifferencesByEntryId[entryId] = notes;
        }
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }

    for (final row in vocabularyComparisonTable.rows.skip(1)) {
      processedRows++;
      final record = _recordForRow(vocabularyComparisonHeaders, row);
      if (record.isEmpty) {
        if (processedRows % _progressUpdateInterval == 0) {
          sendProgress();
        }
        continue;
      }

      final hanji = record['漢字'] ?? '';
      final mandarin = record['華語詞目'] ?? '';
      final dialect = record['腔'] ?? '';
      final romanization = record['羅馬字'] ?? '';
      final entryIds = entryIdsByHanji[hanji];
      if (entryIds != null && hanji.isNotEmpty) {
        final summary = [
          if (mandarin.isNotEmpty) mandarin,
          if (dialect.isNotEmpty) dialect,
        ].join('／');
        final line = [
          if (summary.isNotEmpty) '$summary：',
          hanji,
          if (romanization.isNotEmpty) '（$romanization）',
        ].join();
        for (final entryId in entryIds) {
          vocabularyComparisonsByEntryId
              .putIfAbsent(entryId, () => <String>[])
              .add(line);
        }
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }

    final senseChunk = <Map<String, Object?>>[];
    final sortedSenseKeys = senseRowsByKey.keys.toList()
      ..sort((a, b) {
        final left = a.split(':').map(int.parse).toList(growable: false);
        final right = b.split(':').map(int.parse).toList(growable: false);
        final entryCompare = left.first.compareTo(right.first);
        if (entryCompare != 0) {
          return entryCompare;
        }
        return left.last.compareTo(right.last);
      });
    for (final senseKey in sortedSenseKeys) {
      final row = senseRowsByKey[senseKey]!;
      final senseId = row['sense_id'] as int;
      row['definition_synonyms'] = jsonEncode(
        _dedupePreservingOrder(definitionSynonymsBySenseId[senseId]),
      );
      row['definition_antonyms'] = jsonEncode(
        _dedupePreservingOrder(definitionAntonymsBySenseId[senseId]),
      );
      senseChunk.add(Map<String, Object?>.from(row));
      if (senseChunk.length >= _buildChunkSize) {
        sendPort.send({
          'type': 'chunk',
          'table': _sensesTable,
          'rows': List<Map<String, Object?>>.from(senseChunk),
        });
        senseChunk.clear();
      }
    }
    if (senseChunk.isNotEmpty) {
      sendPort.send({
        'type': 'chunk',
        'table': _sensesTable,
        'rows': List<Map<String, Object?>>.from(senseChunk),
      });
    }

    sendProgress();

    final entryIds = entryRowsById.keys.toList()..sort();
    final entryChunk = <Map<String, Object?>>[];
    for (final entryId in entryIds) {
      final row = entryRowsById[entryId]!;
      final variantChars = _dedupePreservingOrder(
        variantCharsByEntryId[entryId],
      );
      final wordSynonyms = _dedupePreservingOrder(
        wordSynonymsByEntryId[entryId],
      );
      final wordAntonyms = _dedupePreservingOrder(
        wordAntonymsByEntryId[entryId],
      );
      final alternativePronunciations = _dedupePreservingOrder(
        alternativePronunciationsByEntryId[entryId],
      );
      final contractedPronunciations = _dedupePreservingOrder(
        contractedPronunciationsByEntryId[entryId],
      );
      final colloquialPronunciations = _dedupePreservingOrder(
        colloquialPronunciationsByEntryId[entryId],
      );
      final phoneticDifferences = _dedupePreservingOrder(
        phoneticDifferencesByEntryId[entryId],
      );
      final vocabularyComparisons = _dedupePreservingOrder(
        vocabularyComparisonsByEntryId[entryId],
      );
      final hokkienSearch = normalizeQuery(
        [
          row['hanji'] ?? '',
          row['romanization'] ?? '',
          row['category'] ?? '',
          ...variantChars,
          ...alternativePronunciations,
          ...contractedPronunciations,
          ...colloquialPronunciations,
        ].join(' '),
      );
      final mandarinSearch = normalizeQuery(
        mandarinByEntryId[entryId]?.toString() ?? '',
      );
      entryChunk.add(<String, Object?>{
        ...row,
        'variant_chars': jsonEncode(variantChars),
        'word_synonyms': jsonEncode(wordSynonyms),
        'word_antonyms': jsonEncode(wordAntonyms),
        'alternative_pronunciations': jsonEncode(alternativePronunciations),
        'contracted_pronunciations': jsonEncode(contractedPronunciations),
        'colloquial_pronunciations': jsonEncode(colloquialPronunciations),
        'phonetic_differences': jsonEncode(phoneticDifferences),
        'vocabulary_comparisons': jsonEncode(vocabularyComparisons),
        'alias_target_entry_id': aliasTargetByEntryId[entryId],
        'hokkien_search': hokkienSearch,
        'mandarin_search': mandarinSearch,
      });
      if (entryChunk.length >= _buildChunkSize) {
        sendPort.send({
          'type': 'chunk',
          'table': _entriesTable,
          'rows': List<Map<String, Object?>>.from(entryChunk),
        });
        entryChunk.clear();
      }
    }
    if (entryChunk.isNotEmpty) {
      sendPort.send({
        'type': 'chunk',
        'table': _entriesTable,
        'rows': List<Map<String, Object?>>.from(entryChunk),
      });
    }

    final entryCount = entryRowsById.length;
    sendPort.send({
      'type': 'summary',
      'entryCount': entryCount,
      'senseCount': senseCount,
      'exampleCount': exampleCount,
      'totalInsertRows': entryCount + senseCount + exampleCount + 5,
    });
    sendPort.send({'type': 'done'});
  } catch (error, stackTrace) {
    final errorType = switch (error) {
      MissingDictionarySheetException _ => 'missing_sheet',
      FormatException _ => 'corrupted_source',
      _ => 'unexpected',
    };
    sendPort.send({
      'type': 'error',
      'errorType': errorType,
      'message': '$error',
      'stackTrace': '$stackTrace',
      'sheetName': error is MissingDictionarySheetException
          ? error.sheetName
          : null,
      'path': filePath,
    });
  }
}

SpreadsheetTable _requireSheet(SpreadsheetDecoder workbook, String sheetName) {
  final table = workbook.tables[sheetName];
  if (table == null) {
    throw MissingDictionarySheetException(sheetName: sheetName);
  }
  return table;
}

SpreadsheetTable _optionalSheet(SpreadsheetDecoder workbook, String sheetName) {
  return workbook.tables[sheetName] ?? SpreadsheetTable(sheetName);
}

int _dataRowCount(SpreadsheetTable table) {
  if (table.rows.isEmpty) {
    return 0;
  }
  return table.rows.length - 1;
}

List<String> _headersForRows(List<List<dynamic>> rows) {
  if (rows.isEmpty) {
    return const [];
  }
  return rows.first.map(_cellToString).toList(growable: false);
}

Map<String, String> _recordForRow(List<String> headers, List<dynamic> row) {
  if (headers.isEmpty) {
    return const {};
  }

  final values = List<String>.generate(headers.length, (index) {
    if (index >= row.length) {
      return '';
    }
    return _cellToString(row[index]);
  }, growable: false);
  if (values.every((value) => value.isEmpty)) {
    return const {};
  }
  return <String, String>{
    for (var index = 0; index < headers.length; index++)
      headers[index]: values[index].trim(),
  };
}

Object _parseIsolateError(Map<Object?, Object?> message) {
  final errorType = message['errorType'] as String? ?? 'unexpected';
  return switch (errorType) {
    'missing_source' => MissingDictionarySourceException(
      path: message['path'] as String? ?? '',
    ),
    'corrupted_source' => CorruptedDictionarySourceException(
      path: message['path'] as String? ?? '',
    ),
    'missing_sheet' => MissingDictionarySheetException(
      sheetName: message['sheetName'] as String? ?? '',
    ),
    _ => Exception(message['message'] as String? ?? 'Dictionary build failed'),
  };
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

List<String> _splitSlashSeparatedValues(String value) {
  return value
      .split('/')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

void _appendUniqueValue(Map<int, List<String>> target, int key, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return;
  }
  final items = target.putIfAbsent(key, () => <String>[]);
  if (!items.contains(trimmed)) {
    items.add(trimmed);
  }
}

List<String> _dedupePreservingOrder(List<String>? values) {
  if (values == null || values.isEmpty) {
    return const [];
  }
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    result.add(trimmed);
  }
  return result;
}
