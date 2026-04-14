import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';


const _entriesTable = 'dictionary_entries';
const _sensesTable = 'dictionary_senses';
const _examplesTable = 'dictionary_examples';
const _defaultSearchLimit = 60;

class DictionaryRepository {
  static Future<DictionaryBundle>? _bundleFuture;
  static bool useBackgroundSearchIsolate = true;
  static bool preferLocalDatabase = true;
  @visibleForTesting
  static DictionaryBundle? debugFallbackBundle;
  static final Expando<Map<int, DictionaryEntry>> _entriesByIdCache =
      Expando<Map<int, DictionaryEntry>>('dictionaryEntriesById');
  static final Expando<List<Map<String, Object>>> _searchIndexCache =
      Expando<List<Map<String, Object>>>('dictionarySearchIndex');

  final DictionaryDatabaseBuilderService _databaseBuilderService =
      const DictionaryDatabaseBuilderService();

  static void clearBundleCache() {
    _bundleFuture = null;
  }

  static bool get hasDebugFallbackBundle => debugFallbackBundle != null;

  Future<DictionaryBundle> loadBundle() {
    final cachedFuture = _bundleFuture;
    if (cachedFuture != null) {
      return cachedFuture;
    }

    late final Future<DictionaryBundle> future;
    future = _loadBundle().catchError((error, stackTrace) {
      if (identical(_bundleFuture, future)) {
        _bundleFuture = null;
      }
      throw error;
    });
    _bundleFuture = future;
    return future;
  }

  Future<DictionaryBundle> _loadBundle() async {
    if (preferLocalDatabase) {
      final localBundle = await _databaseBuilderService.loadBundleIfAvailable();
      if (localBundle != null) {
        return localBundle;
      }
    }

    final fallbackBundle = debugFallbackBundle;
    if (fallbackBundle != null) {
      return fallbackBundle;
    }

    return const DictionaryBundle(
      entryCount: 0,
      senseCount: 0,
      exampleCount: 0,
      entries: [],
    );
  }

  List<DictionaryEntry> search(DictionaryBundle bundle, String rawQuery) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
    }

    return _resolveSearchResults(
      bundle,
      searchDictionaryEntryIds(_searchIndexFor(bundle), query),
    );
  }

  Future<List<DictionaryEntry>> searchAsync(
    DictionaryBundle bundle,
    String rawQuery, {
    int limit = _defaultSearchLimit,
    int offset = 0,
  }) async {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
    }

    final databasePath = bundle.databasePath;
    if (databasePath != null) {
      return _runDatabaseQueryInBackground(
        (rootToken) async {
          _initializeBackgroundMessenger(rootToken);
          return _searchDatabase(
            databasePath: databasePath,
            query: query,
            limit: limit,
            offset: offset,
          );
        },
        fallback: () => _searchDatabase(
          databasePath: databasePath,
          query: query,
          limit: limit,
          offset: offset,
        ),
      );
    }

    if (!useBackgroundSearchIsolate) {
      return search(bundle, query);
    }

    try {
      final matchedIds = await Isolate.run(
        () => searchDictionaryEntryIds(_searchIndexFor(bundle), query),
      );
      return _resolveSearchResults(bundle, matchedIds);
    } catch (_) {
      return _resolveSearchResults(
        bundle,
        searchDictionaryEntryIds(_searchIndexFor(bundle), query),
      );
    }
  }

  DictionaryEntry? findLinkedEntry(DictionaryBundle bundle, String rawWord) {
    final query = normalizeQuery(rawWord);
    if (query.isEmpty || bundle.isDatabaseBacked) {
      return null;
    }

    DictionaryEntry? romanizationMatch;
    for (final entry in bundle.entries) {
      if (normalizeQuery(entry.hanji) == query) {
        return entry;
      }
      if (entry.variantChars.any(
        (variant) => normalizeQuery(variant) == query,
      )) {
        return entry;
      }
      if (romanizationMatch == null &&
          normalizeQuery(entry.romanization) == query) {
        romanizationMatch = entry;
      }
    }

    return romanizationMatch;
  }

  Future<DictionaryEntry?> findLinkedEntryAsync(
    DictionaryBundle bundle,
    String rawWord,
  ) async {
    final query = normalizeQuery(rawWord);
    if (query.isEmpty) {
      return null;
    }

    final databasePath = bundle.databasePath;
    if (databasePath == null) {
      return findLinkedEntry(bundle, query);
    }

    final results = await _runDatabaseQueryInBackground(
      (rootToken) async {
        _initializeBackgroundMessenger(rootToken);
        return _findLinkedEntryInDatabase(
          databasePath: databasePath,
          query: query,
        );
      },
      fallback: () =>
          _findLinkedEntryInDatabase(databasePath: databasePath, query: query),
    );
    return results;
  }

  Future<List<DictionaryEntry>> entriesByIdsAsync(
    DictionaryBundle bundle,
    Iterable<int> ids,
  ) async {
    final uniqueIds = ids.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) {
      return const [];
    }

    final databasePath = bundle.databasePath;
    if (databasePath == null) {
      final entriesById = _entriesByIdFor(bundle);
      return uniqueIds
          .map((id) => entriesById[id])
          .whereType<DictionaryEntry>()
          .toList(growable: false);
    }

    return _runDatabaseQueryInBackground((rootToken) async {
      _initializeBackgroundMessenger(rootToken);
      return _entriesByIdsFromDatabase(databasePath, uniqueIds);
    }, fallback: () => _entriesByIdsFromDatabase(databasePath, uniqueIds));
  }

  Future<DictionaryEntry?> entryByIdAsync(
    DictionaryBundle bundle,
    int id,
  ) async {
    final entries = await entriesByIdsAsync(bundle, [id]);
    return entries.isEmpty ? null : entries.first;
  }

  List<DictionaryEntry> _resolveSearchResults(
    DictionaryBundle bundle,
    List<int> matchedIds,
  ) {
    return matchedIds
        .map((id) => _entriesByIdFor(bundle)[id])
        .whereType<DictionaryEntry>()
        .toList(growable: false);
  }

  List<Map<String, Object>> _searchIndexFor(DictionaryBundle bundle) {
    final cached = _searchIndexCache[bundle];
    if (cached != null) {
      return cached;
    }

    final built = buildDictionarySearchIndex(bundle.entries);
    _searchIndexCache[bundle] = built;
    return built;
  }

  Map<int, DictionaryEntry> _entriesByIdFor(DictionaryBundle bundle) {
    final cached = _entriesByIdCache[bundle];
    if (cached != null) {
      return cached;
    }

    final built = <int, DictionaryEntry>{
      for (final entry in bundle.entries) entry.id: entry,
    };
    _entriesByIdCache[bundle] = built;
    return built;
  }
}

Future<T> _runDatabaseQueryInBackground<T>(
  Future<T> Function(RootIsolateToken? rootToken) task, {
  required Future<T> Function() fallback,
}) async {
  if (!DictionaryRepository.useBackgroundSearchIsolate) {
    return fallback();
  }

  final rootToken = RootIsolateToken.instance;
  try {
    return await Isolate.run(() => task(rootToken));
  } catch (_) {
    return fallback();
  }
}

void _initializeBackgroundMessenger(RootIsolateToken? rootToken) {
  if (rootToken == null) {
    return;
  }
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
}

Future<List<DictionaryEntry>> _searchDatabase({
  required String databasePath,
  required String query,
  required int limit,
  required int offset,
}) async {
  final likeQuery = '%${_escapeSqlLike(query)}%';
  final database = await _openReadOnlyDatabase(databasePath);
  try {
    final idRows = await database.rawQuery(
      '''
      SELECT id
      FROM $_entriesTable
      WHERE hanji LIKE ? ESCAPE '\\'
         OR hokkien_search LIKE ? ESCAPE '\\'
         OR mandarin_search LIKE ? ESCAPE '\\'
         OR EXISTS (
           SELECT 1
           FROM $_sensesTable
           WHERE $_sensesTable.entry_id = $_entriesTable.id
             AND $_sensesTable.definition LIKE ? ESCAPE '\\'
         )
         OR EXISTS (
           SELECT 1
           FROM $_examplesTable
           WHERE $_examplesTable.entry_id = $_entriesTable.id
             AND (
               $_examplesTable.hanji LIKE ? ESCAPE '\\'
               OR $_examplesTable.mandarin LIKE ? ESCAPE '\\'
             )
         )
      ORDER BY
        CASE
          WHEN hanji = ? THEN 0
          WHEN hokkien_search LIKE ? ESCAPE '\\' THEN 1
          WHEN hanji LIKE ? ESCAPE '\\' THEN 1
          ELSE 2
        END ASC,
        length(hokkien_search) ASC,
        id ASC
      LIMIT ? OFFSET ?
      ''',
      [
        likeQuery,
        likeQuery,
        likeQuery,
        likeQuery,
        likeQuery,
        likeQuery,
        query,
        likeQuery,
        likeQuery,
        limit,
        offset,
      ],
    );
    final ids = idRows.map((row) => row['id'] as int).toList(growable: false);
    return await _entriesByIds(database, ids);
  } finally {
    await database.close();
  }
}

Future<DictionaryEntry?> _findLinkedEntryInDatabase({
  required String databasePath,
  required String query,
}) async {
  final likeQuery = '%${_escapeSqlLike(query)}%';
  final quotedQuery = '%"${_escapeSqlLike(query)}"%';
  final database = await _openReadOnlyDatabase(databasePath);
  try {
    final rows = await database.rawQuery(
      '''
      SELECT id
      FROM $_entriesTable
      WHERE hanji = ?
         OR variant_chars LIKE ? ESCAPE '\\'
         OR hokkien_search LIKE ? ESCAPE '\\'
      ORDER BY
        CASE
          WHEN hanji = ? THEN 0
          WHEN variant_chars LIKE ? ESCAPE '\\' THEN 1
          ELSE 2
        END ASC,
        id ASC
      LIMIT 1
      ''',
      [query, quotedQuery, likeQuery, query, quotedQuery],
    );
    if (rows.isEmpty) {
      return null;
    }
    final entries = await _entriesByIds(database, [rows.first['id'] as int]);
    return entries.isEmpty ? null : entries.first;
  } finally {
    await database.close();
  }
}

Future<List<DictionaryEntry>> _entriesByIdsFromDatabase(
  String databasePath,
  List<int> ids,
) async {
  final database = await _openReadOnlyDatabase(databasePath);
  try {
    return await _entriesByIds(database, ids);
  } finally {
    await database.close();
  }
}

Future<List<DictionaryEntry>> _entriesByIds(
  Database database,
  List<int> ids,
) async {
  if (ids.isEmpty) {
    return const [];
  }

  final placeholders = List.filled(ids.length, '?').join(', ');
  final entryRows = await database.query(
    _entriesTable,
    where: 'id IN ($placeholders)',
    whereArgs: ids,
  );
  if (entryRows.isEmpty) {
    return const [];
  }

  final senseRows = await database.query(
    _sensesTable,
    where: 'entry_id IN ($placeholders)',
    whereArgs: ids,
    orderBy: 'entry_id ASC, sense_id ASC',
  );
  final exampleRows = await database.query(
    _examplesTable,
    where: 'entry_id IN ($placeholders)',
    whereArgs: ids,
    orderBy: 'entry_id ASC, sense_id ASC, example_order ASC, id ASC',
  );

  final examplesBySense = <(int, int), List<DictionaryExample>>{};
  for (final row in exampleRows) {
    final entryId = row['entry_id'] as int;
    final senseId = row['sense_id'] as int;
    examplesBySense
        .putIfAbsent((entryId, senseId), () => <DictionaryExample>[])
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
        .putIfAbsent(entryId, () => <DictionarySense>[])
        .add(
          DictionarySense(
            partOfSpeech: row['part_of_speech'] as String? ?? '',
            definition: row['definition'] as String? ?? '',
            definitionSynonyms: _decodeStoredStringList(
              row['definition_synonyms'],
            ),
            definitionAntonyms: _decodeStoredStringList(
              row['definition_antonyms'],
            ),
            examples: examplesBySense[(entryId, senseId)] ?? const [],
          ),
        );
  }

  final requestedOrder = {
    for (var index = 0; index < ids.length; index++) ids[index]: index,
  };
  final entries =
      entryRows
          .map((row) {
            final entryId = row['id'] as int;
            return DictionaryEntry(
              id: entryId,
              type: row['type'] as String? ?? '',
              hanji: row['hanji'] as String? ?? '',
              romanization: row['romanization'] as String? ?? '',
              category: row['category'] as String? ?? '',
              audioId: row['audio_id'] as String? ?? '',
              hokkienSearch: row['hokkien_search'] as String? ?? '',
              mandarinSearch: row['mandarin_search'] as String? ?? '',
              variantChars: _decodeStoredStringList(row['variant_chars']),
              wordSynonyms: _decodeStoredStringList(row['word_synonyms']),
              wordAntonyms: _decodeStoredStringList(row['word_antonyms']),
              alternativePronunciations: _decodeStoredStringList(
                row['alternative_pronunciations'],
              ),
              contractedPronunciations: _decodeStoredStringList(
                row['contracted_pronunciations'],
              ),
              colloquialPronunciations: _decodeStoredStringList(
                row['colloquial_pronunciations'],
              ),
              phoneticDifferences: _decodeStoredStringList(
                row['phonetic_differences'],
              ),
              vocabularyComparisons: _decodeStoredStringList(
                row['vocabulary_comparisons'],
              ),
              aliasTargetEntryId: row['alias_target_entry_id'] as int?,
              senses: sensesByEntry[entryId] ?? const [],
            );
          })
          .toList(growable: false)
        ..sort((left, right) {
          return (requestedOrder[left.id] ?? ids.length).compareTo(
            requestedOrder[right.id] ?? ids.length,
          );
        });

  return entries;
}

Future<Database> _openReadOnlyDatabase(String databasePath) {
  return databaseFactorySqflitePlugin.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
}

String _escapeSqlLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

List<String> _decodeStoredStringList(Object? value) {
  if (value is! String || value.isEmpty) {
    return const [];
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    return const [];
  }
  if (decoded is! List<dynamic>) {
    return const [];
  }
  return decoded
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
