import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';


class DictionarySearchController extends ChangeNotifier {
  DictionarySearchController({
    required DictionaryRepository repository,
    ChineseTranslationService? translationService,
  }) : _repository = repository,
       _translationService =
           translationService ?? ChineseTranslationService.instance;

  static const _searchHistoryKey = 'recent_search_history';
  static const _maxSearchHistoryItems = 10;
  static const _searchDebounceDuration = Duration(milliseconds: 300);

  final DictionaryRepository _repository;
  final ChineseTranslationService _translationService;
  final TextEditingController searchController = TextEditingController();

  late final Future<DictionaryBundle> bundleFuture;

  DictionaryBundle? _bundle;
  List<DictionaryEntry> _filteredResults = const <DictionaryEntry>[];
  List<String> _searchHistory = const <String>[];
  String _normalizedQuery = '';
  bool _isSearching = false;
  int _searchRequestId = 0;
  Timer? _searchDebounceTimer;
  bool _initialized = false;
  bool _disposed = false;
  Locale _displayLocale = AppLocalizations.traditionalChineseLocale;

  List<DictionaryEntry> get filteredResults => _filteredResults;
  List<String> get searchHistory => _searchHistory;
  String get normalizedQuery => _normalizedQuery;
  bool get isSearching => _isSearching;

  void updateDisplayLocale(Locale locale) {
    final resolved = AppLocalizations.resolveLocale(locale);
    if (_displayLocale == resolved) {
      return;
    }

    _displayLocale = resolved;
    if (_bundle != null) {
      unawaited(_applySearchQuery(forceRefresh: true));
    }
  }

  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    bundleFuture = _loadBundle();
    searchController.addListener(_handleQueryChanged);
    unawaited(_loadSearchHistory());
  }

  @override
  void dispose() {
    _disposed = true;
    searchController.removeListener(_handleQueryChanged);
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<DictionaryBundle> _loadBundle() async {
    final bundle = await _repository.loadBundle();
    if (_disposed) {
      return bundle;
    }

    _bundle = bundle;
    _normalizedQuery = normalizeQuery(searchController.text);
    _filteredResults = const <DictionaryEntry>[];
    notifyListeners();

    if (_normalizedQuery.isNotEmpty) {
      unawaited(applySearchQueryImmediately());
    }

    return bundle;
  }

  Future<void> _loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final storedHistory =
        preferences.getStringList(_searchHistoryKey) ?? const <String>[];
    if (_disposed) {
      return;
    }

    _searchHistory = storedHistory;
    notifyListeners();
  }

  void _handleQueryChanged() {
    if (normalizeQuery(searchController.text).isEmpty) {
      unawaited(applySearchQueryImmediately());
      return;
    }
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      unawaited(_applySearchQuery());
    });
  }

  Future<void> applySearchQueryImmediately({
    bool saveHistoryIfValid = false,
  }) async {
    _searchDebounceTimer?.cancel();
    await _applySearchQuery(saveHistoryIfValid: saveHistoryIfValid);
  }

  Future<void> submitQuery() async {
    await applySearchQueryImmediately(saveHistoryIfValid: true);
  }

  Future<void> _applySearchQuery({
    bool saveHistoryIfValid = false,
    bool forceRefresh = false,
  }) async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final rawQuery = searchController.text;
    final trimmedQuery = rawQuery.trim();
    final convertedQuery = await _translationService.normalizeSearchInput(
      trimmedQuery,
      locale: _displayLocale,
    );
    final normalizedQuery = normalizeQuery(convertedQuery);
    final requestId = ++_searchRequestId;

    if (normalizedQuery.isEmpty) {
      if (_normalizedQuery.isEmpty &&
          _filteredResults.isEmpty &&
          _isSearching == false) {
        return;
      }

      _normalizedQuery = '';
      _filteredResults = const <DictionaryEntry>[];
      _isSearching = false;
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _normalizedQuery == normalizedQuery &&
        _isSearching == false) {
      if (saveHistoryIfValid && _filteredResults.isNotEmpty) {
        await _saveSearchHistory(trimmedQuery);
      }
      return;
    }

    _normalizedQuery = normalizedQuery;
    _isSearching = true;
    notifyListeners();

    late final List<DictionaryEntry> filteredResults;
    try {
      final results = await _repository.searchAsync(bundle, normalizedQuery);
      filteredResults = await _translationService.translateEntriesForDisplay(
        results,
        locale: _displayLocale,
      );
    } catch (_) {
      if (_disposed || requestId != _searchRequestId) {
        return;
      }
      _filteredResults = const <DictionaryEntry>[];
      _isSearching = false;
      notifyListeners();
      return;
    }

    if (_disposed ||
        requestId != _searchRequestId ||
        searchController.text.trim() != trimmedQuery) {
      return;
    }

    _filteredResults = filteredResults;
    _isSearching = false;
    notifyListeners();

    if (saveHistoryIfValid && filteredResults.isNotEmpty) {
      await _saveSearchHistory(trimmedQuery);
    }
  }

  Future<void> clearSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_searchHistoryKey);
    if (_disposed) {
      return;
    }

    _searchHistory = const <String>[];
    notifyListeners();
  }

  void applyHistoryQuery(String query) {
    searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    unawaited(applySearchQueryImmediately());
    unawaited(_saveSearchHistory(query));
  }

  Future<void> saveCurrentQueryIfNeeded() async {
    if (_normalizedQuery.isEmpty ||
        _isSearching ||
        _filteredResults.isEmpty ||
        searchController.text.trim().isEmpty) {
      return;
    }
    await _saveSearchHistory(searchController.text.trim());
  }

  Future<void> _saveSearchHistory(String query) async {
    final nextHistory = <String>[
      query,
      ..._searchHistory.where((item) => item != query),
    ].take(_maxSearchHistoryItems).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_searchHistoryKey, nextHistory);
    if (_disposed) {
      return;
    }

    _searchHistory = nextHistory;
    notifyListeners();
  }
}
