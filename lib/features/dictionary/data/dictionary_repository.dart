import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_search_service.dart';

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
    return _bundleFuture ??= _loadBundle();
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
    String rawQuery,
  ) async {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
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
    if (query.isEmpty) {
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

    if (romanizationMatch != null) {
      return romanizationMatch;
    }

    return null;
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
