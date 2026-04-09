import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:hokkien_dictionary/core/constants/app_constants.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_search_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:sqflite/sqflite.dart';

const _entriesTable = 'dictionary_entries';
const _sensesTable = 'dictionary_senses';
const _examplesTable = 'dictionary_examples';
const _metadataTable = 'dictionary_metadata';
const _buildChunkSize = 250;
const _progressUpdateInterval = 200;

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
    return await databaseFile.length() > 0;
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

  Future<Directory> _dictionaryRootDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory(
      path.join(
        documentsDirectory.path,
        AppConstants.offlineDictionaryDirectoryName,
      ),
    );
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

    final totalRows =
        _dataRowCount(headwordTable) +
        _dataRowCount(senseTable) +
        _dataRowCount(exampleTable);

    final headwordHeaders = _headersForRows(headwordTable.rows);
    final senseHeaders = _headersForRows(senseTable.rows);
    final exampleHeaders = _headersForRows(exampleTable.rows);

    var processedRows = 0;
    final entryRowsById = <int, Map<String, Object?>>{};
    final mandarinByEntryId = <int, StringBuffer>{};

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
        };
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }

    final knownSenseKeys = <String>{};
    final senseChunk = <Map<String, Object?>>[];
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
        final definition = record['解說'] ?? '';
        final partOfSpeech = record['詞性'] ?? '';
        senseChunk.add(<String, Object?>{
          'entry_id': headwordId,
          'sense_id': senseId,
          'part_of_speech': partOfSpeech,
          'definition': definition,
        });
        if (definition.isNotEmpty) {
          mandarinByEntryId
              .putIfAbsent(headwordId, StringBuffer.new)
              .write('$definition ');
        }
        knownSenseKeys.add('$headwordId:$senseId');
        senseCount++;
        if (senseChunk.length >= _buildChunkSize) {
          sendPort.send({
            'type': 'chunk',
            'table': _sensesTable,
            'rows': List<Map<String, Object?>>.from(senseChunk),
          });
          senseChunk.clear();
        }
      }

      if (processedRows % _progressUpdateInterval == 0) {
        sendProgress();
      }
    }
    if (senseChunk.isNotEmpty) {
      sendPort.send({
        'type': 'chunk',
        'table': _sensesTable,
        'rows': List<Map<String, Object?>>.from(senseChunk),
      });
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

    sendProgress();

    final entryIds = entryRowsById.keys.toList()..sort();
    final entryChunk = <Map<String, Object?>>[];
    for (final entryId in entryIds) {
      final row = entryRowsById[entryId]!;
      final hokkienSearch = normalizeQuery(
        '${row['hanji'] ?? ''} ${row['romanization'] ?? ''} ${row['category'] ?? ''}',
      );
      final mandarinSearch = normalizeQuery(
        mandarinByEntryId[entryId]?.toString() ?? '',
      );
      entryChunk.add(<String, Object?>{
        ...row,
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
