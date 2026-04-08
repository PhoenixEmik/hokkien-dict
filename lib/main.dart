import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_audio.dart';

void main() {
  runApp(const HokkienDictionaryApp());
}

class HokkienDictionaryApp extends StatefulWidget {
  const HokkienDictionaryApp({super.key});

  @override
  State<HokkienDictionaryApp> createState() => _HokkienDictionaryAppState();
}

class _HokkienDictionaryAppState extends State<HokkienDictionaryApp> {
  final AppPreferences _appPreferences = AppPreferences();

  @override
  void initState() {
    super.initState();
    unawaited(_appPreferences.initialize());
  }

  @override
  void dispose() {
    _appPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF7F1E7);
    const deepInk = Color(0xFF0E2F35);
    const surface = Color(0xFFFFFFFF);
    const outline = Color(0xFFD7D0C4);
    const mutedText = Color(0xFF5F6C70);

    return AppPreferencesScope(
      notifier: _appPreferences,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '台語辭典',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(
            seedColor: deepInk,
            brightness: Brightness.light,
            surface: surface,
            surfaceContainerLowest: surface,
            surfaceContainerLow: const Color(0xFFFFFBF5),
            outlineVariant: outline,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: deepInk,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            margin: EdgeInsets.zero,
            color: surface,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: outline),
            ),
          ),
          searchBarTheme: SearchBarThemeData(
            elevation: const WidgetStatePropertyAll(3),
            backgroundColor: const WidgetStatePropertyAll(surface),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: WidgetStatePropertyAll(
              Colors.black.withValues(alpha: 0.10),
            ),
            side: const WidgetStatePropertyAll(BorderSide(color: outline)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                color: deepInk,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            hintStyle: const WidgetStatePropertyAll(
              TextStyle(
                color: mutedText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: deepInk.withValues(alpha: 0.07),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class AppPreferences extends ChangeNotifier {
  static const _readingTextScaleKey = 'reading_text_scale';
  static const minReadingTextScale = 0.9;
  static const maxReadingTextScale = 1.4;

  double _readingTextScale = 1.0;

  double get readingTextScale => _readingTextScale;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedScale = preferences.getDouble(_readingTextScaleKey);
    if (storedScale == null) {
      return;
    }
    _readingTextScale = storedScale
        .clamp(minReadingTextScale, maxReadingTextScale)
        .toDouble();
    notifyListeners();
  }

  Future<void> setReadingTextScale(double value) async {
    final nextValue = value
        .clamp(minReadingTextScale, maxReadingTextScale)
        .toDouble();
    if (_readingTextScale == nextValue) {
      return;
    }

    _readingTextScale = nextValue;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_readingTextScaleKey, nextValue);
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferences> {
  const AppPreferencesScope({
    super.key,
    required AppPreferences notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppPreferences of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(
      scope != null,
      'AppPreferencesScope is missing from the widget tree.',
    );
    return scope!.notifier!;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DictionaryRepository _repository = DictionaryRepository();
  final OfflineAudioLibrary _audioLibrary = OfflineAudioLibrary();
  final BookmarkStore _bookmarkStore = BookmarkStore();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
    unawaited(_bookmarkStore.initialize());
  }

  @override
  void dispose() {
    _bookmarkStore.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  Future<void> _downloadArchive(AudioArchiveType type) async {
    final result = await _audioLibrary.downloadArchive(type);
    _showResult(result);
  }

  void _showResult(AudioActionResult result) {
    final message = result.message;
    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result.isError
              ? const Color(0xFF8A3B1F)
              : const Color(0xFF0E2F35),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DictionaryScreen(
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      BookmarksScreen(
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      SettingsScreen(
        audioLibrary: _audioLibrary,
        onDownloadArchive: _downloadArchive,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Dictionary',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({
    super.key,
    required this.repository,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onActionResult,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final ValueChanged<AudioActionResult> onActionResult;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  static const _searchHistoryKey = 'recent_search_history';
  static const _maxSearchHistoryItems = 10;
  static const _searchDebounceDuration = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  late final Future<DictionaryBundle> _bundleFuture;

  DictionaryBundle? _bundle;
  List<DictionaryEntry> _filteredResults = const <DictionaryEntry>[];
  List<String> _searchHistory = const <String>[];
  String _normalizedQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
    _searchController.addListener(_handleQueryChanged);
    unawaited(_loadSearchHistory());
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<DictionaryBundle> _loadBundle() async {
    final bundle = await widget.repository.loadBundle();
    if (!mounted) {
      return bundle;
    }

    setState(() {
      _bundle = bundle;
      _normalizedQuery = normalizeQuery(_searchController.text);
      _filteredResults = _buildFilteredResults(bundle, _searchController.text);
    });

    return bundle;
  }

  Future<void> _loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final storedHistory =
        preferences.getStringList(_searchHistoryKey) ?? const <String>[];
    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = storedHistory;
    });
  }

  void _handleQueryChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, _applySearchQuery);
  }

  void _applySearchQueryImmediately() {
    _searchDebounceTimer?.cancel();
    _applySearchQuery();
  }

  void _applySearchQuery() {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final normalizedQuery = normalizeQuery(_searchController.text);
    final filteredResults = _buildFilteredResults(
      bundle,
      _searchController.text,
    );
    if (_normalizedQuery == normalizedQuery &&
        listEquals(_filteredResults, filteredResults)) {
      return;
    }

    setState(() {
      _normalizedQuery = normalizedQuery;
      _filteredResults = filteredResults;
    });
  }

  void _handleQuerySubmitted(String rawQuery) {
    _applySearchQueryImmediately();
    unawaited(_recordSearchQueryIfValid(rawQuery));
  }

  Future<void> _recordSearchQueryIfValid(String rawQuery) async {
    final bundle = _bundle;
    final trimmedQuery = rawQuery.trim();
    if (bundle == null || trimmedQuery.isEmpty) {
      return;
    }
    if (_buildFilteredResults(bundle, trimmedQuery).isEmpty) {
      return;
    }

    await _saveSearchHistory(trimmedQuery);
  }

  Future<void> _saveSearchHistory(String query) async {
    final nextHistory = <String>[
      query,
      ..._searchHistory.where((item) => item != query),
    ].take(_maxSearchHistoryItems).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_searchHistoryKey, nextHistory);
    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = nextHistory;
    });
  }

  Future<void> _clearSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_searchHistoryKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = const <String>[];
    });
  }

  void _applyHistoryQuery(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _applySearchQueryImmediately();
    unawaited(_saveSearchHistory(query));
  }

  List<DictionaryEntry> _buildFilteredResults(
    DictionaryBundle bundle,
    String rawQuery,
  ) {
    final normalizedQuery = normalizeQuery(rawQuery);
    if (normalizedQuery.isEmpty) {
      return const <DictionaryEntry>[];
    }

    return widget.repository.search(bundle, normalizedQuery);
  }

  Future<void> _playClip(AudioArchiveType type, String clipId) async {
    final result = await widget.audioLibrary.playClip(type, clipId);
    widget.onActionResult(result);
  }

  Future<void> _showEntryDetails(DictionaryEntry entry) async {
    await _recordSearchQueryIfValid(_searchController.text);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(
          entry: entry,
          audioLibrary: widget.audioLibrary,
          bookmarkStore: widget.bookmarkStore,
          onPlayClip: _playClip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DictionaryBundle>(
      future: _bundleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '資料載入失敗：${snapshot.error}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = _searchController.text;
        final hasActiveQuery = _normalizedQuery.isNotEmpty;
        final filteredResults = _filteredResults;
        final searchHistory = _searchHistory;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                  ),
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: SearchWorkspaceCard(
                            controller: _searchController,
                            onSubmitted: _handleQuerySubmitted,
                          ),
                        ),
                      ),
                      if (!hasActiveQuery && searchHistory.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: SearchHistorySection(
                              history: searchHistory,
                              onHistoryTap: _applyHistoryQuery,
                              onClearHistory: _clearSearchHistory,
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: !hasActiveQuery
                            ? SliverToBoxAdapter(
                                child: EmptyState(query: query),
                              )
                            : filteredResults.isEmpty
                            ? const SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 220,
                                  child: NoResultsState(),
                                ),
                              )
                            : SliverList.separated(
                                itemCount: filteredResults.length,
                                itemBuilder: (context, index) {
                                  return EntryListItem(
                                    entry: filteredResults[index],
                                    onTap: () => _showEntryDetails(
                                      filteredResults[index],
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return const SizedBox(height: 10);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.onDownloadArchive,
  });

  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;

  @override
  Widget build(BuildContext context) {
    final appPreferences = AppPreferencesScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([audioLibrary, appPreferences]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('設定')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                  ),
                  child: ListTileTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                      children: [
                        const SettingsSectionHeader(title: '離線資源'),
                        AudioResourceTile(
                          type: AudioArchiveType.word,
                          audioLibrary: audioLibrary,
                          onDownload: onDownloadArchive,
                        ),
                        AudioResourceTile(
                          type: AudioArchiveType.sentence,
                          audioLibrary: audioLibrary,
                          onDownload: onDownloadArchive,
                        ),
                        const Divider(height: 32),
                        const SettingsSectionHeader(title: '閱讀文字'),
                        SettingsTextScaleTile(
                          value: appPreferences.readingTextScale,
                          onChanged: (value) {
                            unawaited(
                              appPreferences.setReadingTextScale(value),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        const SettingsSectionHeader(title: '關於'),
                        AboutListTile(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF17454C),
                          ),
                          applicationName: '台語辭典',
                          applicationLegalese:
                              'App code: MIT\nDictionary data and audio: 教育部《臺灣台語常用詞辭典》衍生內容，採 CC BY-NC-ND 2.5 TW。',
                          aboutBoxChildren: const [
                            SizedBox(height: 12),
                            Text('台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。'),
                            SizedBox(height: 12),
                            Text(
                              '參考頁面：https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
                            ),
                          ],
                          applicationIcon: const Icon(
                            Icons.menu_book_outlined,
                            color: Color(0xFF17454C),
                          ),
                          child: const Text('關於台語辭典'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.repository,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onActionResult,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final ValueChanged<AudioActionResult> onActionResult;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final Future<DictionaryBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = widget.repository.loadBundle();
  }

  Future<void> _playClip(AudioArchiveType type, String clipId) async {
    final result = await widget.audioLibrary.playClip(type, clipId);
    widget.onActionResult(result);
  }

  Future<void> _showEntryDetails(DictionaryEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(
          entry: entry,
          audioLibrary: widget.audioLibrary,
          bookmarkStore: widget.bookmarkStore,
          onPlayClip: _playClip,
        ),
      ),
    );
  }

  List<DictionaryEntry> _buildBookmarkedEntries(DictionaryBundle bundle) {
    final entriesById = <int, DictionaryEntry>{
      for (final entry in bundle.entries) entry.id: entry,
    };
    return widget.bookmarkStore.bookmarkedIds
        .map((id) => entriesById[id])
        .whereType<DictionaryEntry>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.bookmarkStore,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('書籤')),
          body: FutureBuilder<DictionaryBundle>(
            future: _bundleFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '資料載入失敗：${snapshot.error}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookmarkedEntries = _buildBookmarkedEntries(snapshot.data!);
              if (bookmarkedEntries.isEmpty) {
                return const BookmarkEmptyState();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: bookmarkedEntries.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == bookmarkedEntries.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: EntryListItem(
                              entry: bookmarkedEntries[index],
                              onTap: () =>
                                  _showEntryDetails(bookmarkedEntries[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class SearchWorkspaceCard extends StatelessWidget {
  const SearchWorkspaceCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: '輸入台語漢字、白話字或華語詞義',
      leading: const Icon(Icons.search),
      trailing: controller.text.isEmpty
          ? null
          : [
              IconButton(
                onPressed: () {
                  controller.clear();
                },
                icon: const Icon(Icons.close),
              ),
            ],
      onSubmitted: onSubmitted,
    );
  }
}

class SearchHistorySection extends StatelessWidget {
  const SearchHistorySection({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearHistory,
  });

  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final Future<void> Function() onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '搜尋紀錄',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF18363C),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '清除搜尋紀錄',
                  onPressed: onClearHistory,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map((query) {
                    return ActionChip(
                      label: Text(query),
                      avatar: const Icon(Icons.history, size: 18),
                      onPressed: () => onHistoryTap(query),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class SettingsTextScaleTile extends StatelessWidget {
  const SettingsTextScaleTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: const Text('字級'),
      trailing: Text(
        '${(value * 100).round()}%',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: value,
              min: AppPreferences.minReadingTextScale,
              max: AppPreferences.maxReadingTextScale,
              divisions: 5,
              label: _readingTextScaleLabel(value),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('小', style: theme.textTheme.bodySmall),
                Text('特大', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AudioResourceTile extends StatelessWidget {
  const AudioResourceTile({
    super.key,
    required this.type,
    required this.audioLibrary,
    required this.onDownload,
  });

  final AudioArchiveType type;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownload;

  @override
  Widget build(BuildContext context) {
    final isReady = audioLibrary.isArchiveReady(type);
    final isDownloading = audioLibrary.isDownloading(type);
    final progress = audioLibrary.downloadProgress(type);
    final statusText = isDownloading
        ? audioLibrary.downloadStatus(type)
        : isReady
        ? '已下載，可離線播放'
        : '大小約 ${formatBytes(type.archiveBytes)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        type == AudioArchiveType.word
            ? Icons.record_voice_over_outlined
            : Icons.chat_bubble_outline,
        color: const Color(0xFF17454C),
      ),
      title: Text(
        type.displayLabel,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF18363C),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.archiveFileName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF66797D)),
            ),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6D71)),
            ),
            if (isDownloading && progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        onPressed: isDownloading ? null : () => onDownload(type),
        child: isDownloading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isReady ? '重新下載' : '下載'),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = query.trim().isEmpty ? '開始搜尋' : '找不到符合的結果';
    final body = query.trim().isEmpty
        ? '輸入台語漢字、白話字，或華語釋義後才顯示詞條。'
        : '換個寫法試試看，或改用另一個查詢方向。';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoResultsState extends StatelessWidget {
  const NoResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '找不到符合的詞條',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5A6D71),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BookmarkEmptyState extends StatelessWidget {
  const BookmarkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 44,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              '尚未加入任何書籤',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF18363C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '從詞條詳細頁點選書籤圖示，就會顯示在這裡。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EntryListItem extends StatelessWidget {
  const EntryListItem({super.key, required this.entry, required this.onTap});

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleAlignment: ListTileTitleAlignment.top,
        title: Text(
          entry.hanji.isEmpty ? '未標記漢字' : entry.hanji,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF18363C),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.romanization.isNotEmpty)
              Text(
                entry.romanization,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFC9752D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (entry.briefSummary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.briefSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5A6D71),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF708286)),
        onTap: onTap,
      ),
    );
  }
}

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onPlayClip,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bookmarkStore,
      builder: (context, child) {
        final isBookmarked = bookmarkStore.isBookmarked(entry.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(entry.hanji.isEmpty ? '詞條詳細資料' : entry.hanji),
            actions: [
              IconButton(
                tooltip: isBookmarked ? '移除書籤' : '加入書籤',
                onPressed: () {
                  unawaited(bookmarkStore.toggleBookmark(entry.id));
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),
          body: AnimatedBuilder(
            animation: audioLibrary,
            builder: (context, child) {
              return WordDetailBody(
                entry: entry,
                audioLibrary: audioLibrary,
                onPlayClip: onPlayClip,
              );
            },
          ),
        );
      },
    );
  }
}

class WordDetailBody extends StatelessWidget {
  const WordDetailBody({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.onPlayClip,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingTextScale = AppPreferencesScope.of(context).readingTextScale;
    final subtitle = [
      if (entry.type.isNotEmpty) entry.type,
      if (entry.category.isNotEmpty) entry.category,
    ].join(' · ');

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.hanji.isEmpty ? '未標記漢字' : entry.hanji,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0E2F35),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.romanization.isNotEmpty)
                          Text(
                            entry.romanization,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFC9752D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF54696D),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: entry.audioId.isEmpty
                        ? null
                        : AudioButton(
                            type: AudioArchiveType.word,
                            audioId: entry.audioId,
                            audioLibrary: audioLibrary,
                            onPressed: onPlayClip,
                          ),
                  ),
                  const SizedBox(height: 20),
                  ...entry.senses.map((sense) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (sense.partOfSpeech.isNotEmpty)
                                Chip(label: Text(sense.partOfSpeech)),
                              if (sense.definition.isNotEmpty)
                                Text(
                                  sense.definition,
                                  style: _scaledTextStyle(
                                    theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.55,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    readingTextScale,
                                  ),
                                ),
                            ],
                          ),
                          if (sense.examples.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...sense.examples.take(3).map((example) {
                              return ExampleListTile(
                                example: example,
                                audioLibrary: audioLibrary,
                                onPlayClip: onPlayClip,
                                textScale: readingTextScale,
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '顯示符合查詢的台語詞目與華語義項',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF617176),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExampleListTile extends StatelessWidget {
  const ExampleListTile({
    super.key,
    required this.example,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.textScale,
  });

  final DictionaryExample example;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFF7F2E8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: example.hanji.isEmpty
            ? null
            : Text(
                example.hanji,
                style: _scaledTextStyle(
                  theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textScale,
                ),
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (example.romanization.isNotEmpty)
              Text(
                example.romanization,
                style: _scaledTextStyle(
                  theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B5C3A),
                  ),
                  textScale,
                ),
              ),
            if (example.mandarin.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                example.mandarin,
                style: _scaledTextStyle(
                  theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF35545B),
                    height: 1.5,
                  ),
                  textScale,
                ),
              ),
            ],
          ],
        ),
        trailing: example.audioId.isEmpty
            ? null
            : AudioButton(
                type: AudioArchiveType.sentence,
                audioId: example.audioId,
                audioLibrary: audioLibrary,
                onPressed: onPlayClip,
                compact: true,
              ),
      ),
    );
  }
}

TextStyle? _scaledTextStyle(TextStyle? style, double scale) {
  if (style == null || style.fontSize == null) {
    return style;
  }
  return style.copyWith(fontSize: style.fontSize! * scale);
}

String _readingTextScaleLabel(double value) {
  if (value <= 0.95) {
    return '較小';
  }
  if (value >= 1.35) {
    return '特大';
  }
  if (value >= 1.15) {
    return '較大';
  }
  return '標準';
}

class AudioButton extends StatelessWidget {
  const AudioButton({
    super.key,
    required this.type,
    required this.audioId,
    required this.audioLibrary,
    required this.onPressed,
    this.compact = false,
  });

  final AudioArchiveType type;
  final String audioId;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLoading = audioLibrary.isClipLoading(type, audioId);
    final isPlaying = audioLibrary.isClipPlaying(type, audioId);
    final archiveReady = audioLibrary.isArchiveReady(type);
    final buttonSize = compact ? 42.0 : 48.0;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0E2F35).withValues(alpha: 0.08),
          foregroundColor: const Color(0xFF0E2F35),
          padding: EdgeInsets.zero,
        ),
        onPressed: isLoading ? null : () => onPressed(type, audioId),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isPlaying
                    ? Icons.stop_circle_outlined
                    : archiveReady
                    ? Icons.volume_up_outlined
                    : Icons.download_outlined,
                size: compact ? 20 : 22,
              ),
      ),
    );
  }
}

class BookmarkStore extends ChangeNotifier {
  static const _bookmarkIdsKey = 'bookmarked_entry_ids';

  List<int> _bookmarkedIds = const <int>[];

  List<int> get bookmarkedIds => List<int>.unmodifiable(_bookmarkedIds);

  bool isBookmarked(int entryId) {
    return _bookmarkedIds.contains(entryId);
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedIds = preferences.getStringList(_bookmarkIdsKey) ?? const [];
    _bookmarkedIds = storedIds
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> toggleBookmark(int entryId) async {
    final nextIds = isBookmarked(entryId)
        ? _bookmarkedIds.where((id) => id != entryId).toList(growable: false)
        : <int>[entryId, ..._bookmarkedIds.where((id) => id != entryId)];
    _bookmarkedIds = nextIds;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _bookmarkIdsKey,
      _bookmarkedIds.map((id) => '$id').toList(growable: false),
    );
    notifyListeners();
  }
}

class DictionaryRepository {
  static Future<DictionaryBundle>? _bundleFuture;

  Future<DictionaryBundle> loadBundle() {
    return _bundleFuture ??= _loadBundle();
  }

  Future<DictionaryBundle> _loadBundle() async {
    final data = await rootBundle.load('assets/data/dictionary.json.gz');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final jsonString = utf8.decode(GZipCodec().decode(bytes));
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return DictionaryBundle.fromJson(decoded);
  }

  List<DictionaryEntry> search(DictionaryBundle bundle, String rawQuery) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
    }

    final matched = <_ScoredEntry>[];
    for (final entry in bundle.entries) {
      final match = _matchEntry(entry, query);
      if (match != null) {
        matched.add(match);
      }
    }

    matched.sort((left, right) {
      final comparePriority = left.score.compareTo(right.score);
      if (comparePriority != 0) {
        return comparePriority;
      }

      final compareLength = left.matchedLength.compareTo(right.matchedLength);
      if (compareLength != 0) {
        return compareLength;
      }

      return left.entry.id.compareTo(right.entry.id);
    });

    return matched.take(60).map((item) => item.entry).toList(growable: false);
  }

  _ScoredEntry? _matchEntry(DictionaryEntry entry, String query) {
    final headwordMatch = _bestMatchLength(
      _headwordFieldsForEntry(entry),
      query,
    );
    if (headwordMatch != null) {
      final score = headwordMatch == query.length ? 0 : 1;
      return _ScoredEntry(entry, score, headwordMatch);
    }

    final definitionMatch = _bestMatchLength(
      _definitionFieldsForEntry(entry),
      query,
    );
    if (definitionMatch == null) {
      return null;
    }
    return _ScoredEntry(entry, 2, definitionMatch);
  }

  List<String> _headwordFieldsForEntry(DictionaryEntry entry) {
    final fields = <String>{};
    final hanji = normalizeQuery(entry.hanji);
    if (hanji.isNotEmpty) {
      fields.add(hanji);
    }
    final romanization = normalizeQuery(entry.romanization);
    if (romanization.isNotEmpty) {
      fields.add(romanization);
    }
    return fields.toList(growable: false);
  }

  List<String> _definitionFieldsForEntry(DictionaryEntry entry) {
    return entry.senses
        .map((sense) => normalizeQuery(sense.definition))
        .where((definition) => definition.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int? _bestMatchLength(List<String> fields, String query) {
    int? bestLength;
    for (final field in fields) {
      if (field.isEmpty || query.isEmpty || !field.contains(query)) {
        continue;
      }
      if (bestLength == null || field.length < bestLength) {
        bestLength = field.length;
      }
    }
    return bestLength;
  }
}

class _ScoredEntry {
  const _ScoredEntry(this.entry, this.score, this.matchedLength);

  final DictionaryEntry entry;
  final int score;
  final int matchedLength;
}

class DictionaryBundle {
  const DictionaryBundle({
    required this.entryCount,
    required this.senseCount,
    required this.exampleCount,
    required this.entries,
  });

  factory DictionaryBundle.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionaryEntry.fromJson)
        .toList(growable: false);
    return DictionaryBundle(
      entryCount: json['entryCount'] as int,
      senseCount: json['senseCount'] as int,
      exampleCount: json['exampleCount'] as int,
      entries: entries,
    );
  }

  final int entryCount;
  final int senseCount;
  final int exampleCount;
  final List<DictionaryEntry> entries;
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.type,
    required this.hanji,
    required this.romanization,
    required this.category,
    required this.audioId,
    required this.hokkienSearch,
    required this.mandarinSearch,
    required this.senses,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final senses = (json['senses'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionarySense.fromJson)
        .toList(growable: false);
    return DictionaryEntry(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      hanji: json['hanji'] as String? ?? '',
      romanization: json['romanization'] as String? ?? '',
      category: json['category'] as String? ?? '',
      audioId: json['audio'] as String? ?? '',
      hokkienSearch: json['hokkienSearch'] as String? ?? '',
      mandarinSearch: json['mandarinSearch'] as String? ?? '',
      senses: senses,
    );
  }

  final int id;
  final String type;
  final String hanji;
  final String romanization;
  final String category;
  final String audioId;
  final String hokkienSearch;
  final String mandarinSearch;
  final List<DictionarySense> senses;

  String get briefSummary {
    for (final sense in senses) {
      if (sense.definition.isNotEmpty) {
        return sense.definition;
      }
    }

    if (category.isNotEmpty) {
      return category;
    }

    if (type.isNotEmpty) {
      return type;
    }

    return romanization;
  }
}

class DictionarySense {
  const DictionarySense({
    required this.partOfSpeech,
    required this.definition,
    required this.examples,
  });

  factory DictionarySense.fromJson(Map<String, dynamic> json) {
    final examples = (json['examples'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionaryExample.fromJson)
        .toList(growable: false);
    return DictionarySense(
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      examples: examples,
    );
  }

  final String partOfSpeech;
  final String definition;
  final List<DictionaryExample> examples;
}

class DictionaryExample {
  const DictionaryExample({
    required this.hanji,
    required this.romanization,
    required this.mandarin,
    required this.audioId,
  });

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      hanji: json['hanji'] as String? ?? '',
      romanization: json['romanization'] as String? ?? '',
      mandarin: json['mandarin'] as String? ?? '',
      audioId: json['audio'] as String? ?? '',
    );
  }

  final String hanji;
  final String romanization;
  final String mandarin;
  final String audioId;
}

String normalizeQuery(String input) {
  var normalized = removeTones(input.trim());
  normalized = normalized.replaceAll(RegExp(r'[1-8]'), '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  normalized = normalized.replaceAll(RegExp(r'[-_/]'), ' ');
  normalized = normalized.replaceAll(RegExp("[【】\\[\\]（）()、,.;:!?\"'`]+"), ' ');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String removeTones(String input) {
  var normalized = input.toLowerCase();
  for (final entry in _romanizationFold.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  normalized = normalized.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  normalized = normalized.replaceAll('o͘', 'oo');
  normalized = normalized.replaceAll('ⁿ', 'n');
  normalized = normalized.replaceAll(RegExp(r'[1-8]'), '');
  return normalized;
}

const Map<String, String> _romanizationFold = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ǎ': 'a',
  'ā': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ē': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ī': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ō': 'o',
  'ö': 'o',
  'ő': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ū': 'u',
  'ü': 'u',
  'ḿ': 'm',
  'm̀': 'm',
  'm̂': 'm',
  'ń': 'n',
  'ǹ': 'n',
  'n̂': 'n',
};
