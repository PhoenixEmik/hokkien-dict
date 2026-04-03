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

class HokkienDictionaryApp extends StatelessWidget {
  const HokkienDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF7F1E7);
    const deepInk = Color(0xFF0E2F35);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '台語辭典',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepInk,
          brightness: Brightness.light,
          surface: canvas,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: deepInk,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.94),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
    );
  }
}

enum SearchDirection { hokkienToMandarin, mandarinToHokkien }

enum SearchBarPlacement { top, bottom }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DictionaryRepository _repository = DictionaryRepository();
  final OfflineAudioLibrary _audioLibrary = OfflineAudioLibrary();

  int _selectedIndex = 0;
  SearchBarPlacement _searchBarPlacement = SearchBarPlacement.top;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
    unawaited(_loadPreferences());
  }

  @override
  void dispose() {
    _audioLibrary.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString('search_bar_placement');
    if (!mounted || storedValue == null) {
      return;
    }

    setState(() {
      _searchBarPlacement = storedValue == SearchBarPlacement.bottom.name
          ? SearchBarPlacement.bottom
          : SearchBarPlacement.top;
    });
  }

  Future<void> _downloadArchive(AudioArchiveType type) async {
    final result = await _audioLibrary.downloadArchive(type);
    _showResult(result);
  }

  Future<void> _updateSearchBarPlacement(SearchBarPlacement placement) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('search_bar_placement', placement.name);
    if (!mounted) {
      return;
    }

    setState(() {
      _searchBarPlacement = placement;
    });
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
        searchBarPlacement: _searchBarPlacement,
        onActionResult: _showResult,
      ),
      SettingsScreen(
        audioLibrary: _audioLibrary,
        searchBarPlacement: _searchBarPlacement,
        onDownloadArchive: _downloadArchive,
        onSearchBarPlacementChanged: _updateSearchBarPlacement,
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
    required this.searchBarPlacement,
    required this.onActionResult,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final SearchBarPlacement searchBarPlacement;
  final ValueChanged<AudioActionResult> onActionResult;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<DictionaryBundle> _bundleFuture;

  SearchDirection _direction = SearchDirection.hokkienToMandarin;
  DictionaryBundle? _bundle;
  List<DictionaryEntry> _filteredResults = const <DictionaryEntry>[];
  String _normalizedQuery = '';

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
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
      _filteredResults = _buildFilteredResults(
        bundle,
        _direction,
        _searchController.text,
      );
    });

    return bundle;
  }

  void _handleQueryChanged() {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }

    final normalizedQuery = normalizeQuery(_searchController.text);
    final filteredResults = _buildFilteredResults(
      bundle,
      _direction,
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

  List<DictionaryEntry> _buildFilteredResults(
    DictionaryBundle bundle,
    SearchDirection direction,
    String rawQuery,
  ) {
    final normalizedQuery = normalizeQuery(rawQuery);
    if (normalizedQuery.isEmpty) {
      return const <DictionaryEntry>[];
    }

    return widget.repository.search(bundle, direction, normalizedQuery);
  }

  void _handleDirectionChanged(SearchDirection direction) {
    if (_direction == direction) {
      return;
    }

    setState(() {
      _direction = direction;
      _normalizedQuery = normalizeQuery(_searchController.text);
      _filteredResults = _bundle == null
          ? const <DictionaryEntry>[]
          : _buildFilteredResults(
              _bundle!,
              direction,
              _searchController.text,
            );
    });
  }

  Future<void> _playClip(AudioArchiveType type, String clipId) async {
    final result = await widget.audioLibrary.playClip(type, clipId);
    widget.onActionResult(result);
  }

  Future<void> _showEntryDetails(DictionaryEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedBuilder(
          animation: widget.audioLibrary,
          builder: (context, child) {
            return EntryDetailSheet(
              entry: entry,
              direction: _direction,
              audioLibrary: widget.audioLibrary,
              onPlayClip: _playClip,
            );
          },
        );
      },
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

        final bundle = _bundle ?? snapshot.data!;
        final query = _searchController.text;
        final hasActiveQuery = _normalizedQuery.isNotEmpty;
        final filteredResults = _filteredResults;
        final showSearchOnTop =
            widget.searchBarPlacement == SearchBarPlacement.top;

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
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: CompactHeaderCard(
                            title: '台語辭典',
                            subtitle: '先搜尋，再點選詞條看完整解說與例句。',
                            onInfoPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  const DictionaryAboutDialog(),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: StatisticsPanel(bundle: bundle),
                        ),
                      ),
                      if (showSearchOnTop)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: SearchWorkspaceCard(
                              direction: _direction,
                              controller: _searchController,
                              onDirectionChanged: _handleDirectionChanged,
                              onQueryChanged: (_) => _handleQueryChanged(),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: !hasActiveQuery
                            ? SliverToBoxAdapter(
                                child: EmptyState(
                                  query: query,
                                  searchBarPlacement: widget.searchBarPlacement,
                                ),
                              )
                            : filteredResults.isEmpty
                            ? const SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 220,
                                  child: NoResultsState(),
                                ),
                              )
                            : SliverMainAxisGroup(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                        left: 4,
                                      ),
                                      child: Text(
                                        '搜尋結果',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF18363C),
                                            ),
                                      ),
                                    ),
                                  ),
                                  SliverList.separated(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      return EntryListItem(
                                        entry: filteredResults[index],
                                        onTap: () =>
                                            _showEntryDetails(
                                              filteredResults[index],
                                            ),
                                      );
                                    },
                                    separatorBuilder: (context, index) {
                                      return const SizedBox(height: 10);
                                    },
                                  ),
                                  if (!showSearchOnTop)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: SearchWorkspaceCard(
                                          direction: _direction,
                                          controller: _searchController,
                                          onDirectionChanged:
                                              _handleDirectionChanged,
                                          onQueryChanged: (_) =>
                                              _handleQueryChanged(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      if (!showSearchOnTop && filteredResults.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          sliver: SliverToBoxAdapter(
                            child: SearchWorkspaceCard(
                              direction: _direction,
                              controller: _searchController,
                              onDirectionChanged: _handleDirectionChanged,
                              onQueryChanged: (_) => _handleQueryChanged(),
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
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.searchBarPlacement,
    required this.onDownloadArchive,
    required this.onSearchBarPlacementChanged,
  });

  final OfflineAudioLibrary audioLibrary;
  final SearchBarPlacement searchBarPlacement;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;
  final Future<void> Function(SearchBarPlacement placement)
  onSearchBarPlacementChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioLibrary,
      builder: (context, child) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompactHeaderCard(
                          title: 'Settings',
                          subtitle: '控制搜尋欄位置與離線語音資源。',
                          accentLabel:
                              '${AudioArchiveType.values.where(audioLibrary.isArchiveReady).length} / 2 套資源已就緒',
                          onInfoPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => const AudioAboutDialog(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SearchPlacementSection(
                          placement: searchBarPlacement,
                          onPlacementChanged: onSearchBarPlacementChanged,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Audio Resource Management',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF18363C),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '將詞目音檔與例句音檔集中管理。',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF5A6D71),
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        AudioManagementSection(
                          audioLibrary: audioLibrary,
                          onDownloadArchive: onDownloadArchive,
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

class CompactHeaderCard extends StatelessWidget {
  const CompactHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onInfoPressed,
    this.accentLabel,
  });

  final String title;
  final String subtitle;
  final String? accentLabel;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF15505A), Color(0xFF23727E), Color(0xFFE7C863)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123E45).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.45,
                    ),
                  ),
                  if (accentLabel != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        accentLabel!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
              ),
              onPressed: onInfoPressed,
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key, required this.bundle});

  final DictionaryBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StatisticChip(
              icon: Icons.menu_book_outlined,
              label: '詞目',
              value: '${bundle.entryCount}',
            ),
            StatisticChip(
              icon: Icons.notes_outlined,
              label: '義項',
              value: '${bundle.senseCount}',
            ),
            StatisticChip(
              icon: Icons.forum_outlined,
              label: '例句',
              value: '${bundle.exampleCount}',
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticChip extends StatelessWidget {
  const StatisticChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF245963)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18363C),
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5A6D71),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchWorkspaceCard extends StatelessWidget {
  const SearchWorkspaceCard({
    super.key,
    required this.direction,
    required this.controller,
    required this.onDirectionChanged,
    required this.onQueryChanged,
  });

  final SearchDirection direction;
  final TextEditingController controller;
  final ValueChanged<SearchDirection> onDirectionChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintText = switch (direction) {
      SearchDirection.hokkienToMandarin => '輸入台語漢字或白話字',
      SearchDirection.mandarinToHokkien => '輸入華語詞義',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SearchDirection>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<SearchDirection>(
                    value: SearchDirection.hokkienToMandarin,
                    label: Text('台語 → 華語'),
                    icon: Icon(Icons.east),
                  ),
                  ButtonSegment<SearchDirection>(
                    value: SearchDirection.mandarinToHokkien,
                    label: Text('華語 → 台語'),
                    icon: Icon(Icons.west),
                  ),
                ],
                selected: {direction},
                onSelectionChanged: (selection) {
                  onDirectionChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: const Color(0xFFF6F2EA),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '預設不顯示任何詞條，輸入關鍵字後才顯示結果。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A7B7F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPlacementSection extends StatelessWidget {
  const SearchPlacementSection({
    super.key,
    required this.placement,
    required this.onPlacementChanged,
  });

  final SearchBarPlacement placement;
  final Future<void> Function(SearchBarPlacement placement) onPlacementChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Bar Position',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18363C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '把搜尋欄固定在統計區塊下方，或移到結果列表底部。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<SearchBarPlacement>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<SearchBarPlacement>(
                  value: SearchBarPlacement.top,
                  icon: Icon(Icons.vertical_align_top),
                  label: Text('Top'),
                ),
                ButtonSegment<SearchBarPlacement>(
                  value: SearchBarPlacement.bottom,
                  icon: Icon(Icons.vertical_align_bottom),
                  label: Text('Bottom'),
                ),
              ],
              selected: {placement},
              onSelectionChanged: (selection) {
                unawaited(onPlacementChanged(selection.first));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AudioManagementSection extends StatelessWidget {
  const AudioManagementSection({
    super.key,
    required this.audioLibrary,
    required this.onDownloadArchive,
  });

  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            CompactAudioResourceCard(
              type: AudioArchiveType.word,
              audioLibrary: audioLibrary,
              onDownload: onDownloadArchive,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            CompactAudioResourceCard(
              type: AudioArchiveType.sentence,
              audioLibrary: audioLibrary,
              onDownload: onDownloadArchive,
            ),
          ],
        ),
      ),
    );
  }
}

class CompactAudioResourceCard extends StatelessWidget {
  const CompactAudioResourceCard({
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4F3),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              type == AudioArchiveType.word
                  ? Icons.record_voice_over_outlined
                  : Icons.chat_bubble_outline,
              color: const Color(0xFF17454C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18363C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.archiveFileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66797D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isReady
                          ? Icons.check_circle
                          : Icons.cloud_download_outlined,
                      size: 16,
                      color: isReady
                          ? const Color(0xFF1A7F53)
                          : const Color(0xFFC9752D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isDownloading
                            ? audioLibrary.downloadStatus(type)
                            : isReady
                            ? '已下載，可離線播放'
                            : '大小約 ${formatBytes(type.archiveBytes)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5A6D71),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isDownloading && progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: const Color(0xFFF2D18B),
              foregroundColor: const Color(0xFF0E2F35),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: isDownloading ? null : () => onDownload(type),
            child: isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isReady ? '重新下載' : '下載'),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.query,
    required this.searchBarPlacement,
  });

  final String query;
  final SearchBarPlacement searchBarPlacement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = query.trim().isEmpty ? '開始搜尋' : '找不到符合的結果';
    final body = query.trim().isEmpty
        ? searchBarPlacement == SearchBarPlacement.top
              ? '輸入台語漢字、白話字，或華語釋義後才顯示詞條。'
              : '搜尋欄目前放在下方，輸入關鍵字後才顯示詞條。'
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

class EntryListItem extends StatelessWidget {
  const EntryListItem({super.key, required this.entry, required this.onTap});

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4ED),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC9752D),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.hanji.isEmpty ? '未標記漢字' : entry.hanji,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18363C),
                    ),
                  ),
                  if (entry.romanization.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.romanization,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFC9752D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (entry.briefSummary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.briefSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5A6D71),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF708286)),
          ],
        ),
      ),
    );
  }
}

class EntryDetailSheet extends StatelessWidget {
  const EntryDetailSheet({
    super.key,
    required this.entry,
    required this.direction,
    required this.audioLibrary,
    required this.onPlayClip,
  });

  final DictionaryEntry entry;
  final SearchDirection direction;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (entry.type.isNotEmpty) entry.type,
      if (entry.category.isNotEmpty) entry.category,
    ].join(' · ');

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F1E7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CA9AC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.hanji.isEmpty ? '未標記漢字' : entry.hanji,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0E2F35),
                              ),
                            ),
                            if (entry.romanization.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                entry.romanization,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFC9752D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
                      ),
                      if (entry.audioId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: AudioButton(
                            type: AudioArchiveType.word,
                            audioId: entry.audioId,
                            audioLibrary: audioLibrary,
                            onPressed: onPlayClip,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.55,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            if (sense.examples.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...sense.examples.take(3).map((example) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F2E8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (example.hanji.isNotEmpty)
                                              Text(
                                                example.hanji,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            if (example
                                                .romanization
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                example.romanization,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF6B5C3A,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                            if (example
                                                .mandarin
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                example.mandarin,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF35545B,
                                                      ),
                                                      height: 1.5,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (example.audioId.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          child: AudioButton(
                                            type: AudioArchiveType.sentence,
                                            audioId: example.audioId,
                                            audioLibrary: audioLibrary,
                                            onPressed: onPlayClip,
                                            compact: true,
                                          ),
                                        ),
                                    ],
                                  ),
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
                        direction == SearchDirection.hokkienToMandarin
                            ? '顯示台語詞目對應的華語義項'
                            : '顯示命中華語釋義後對應的台語詞目',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF617176),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class DictionaryAboutDialog extends StatelessWidget {
  const DictionaryAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About Dictionary'),
      content: const Text('搜尋結果現在採扁平列表，不再分組。畫面預設不顯示任何詞條，使用者輸入後才會看到結果。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

class AudioAboutDialog extends StatelessWidget {
  const AudioAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About Audio Downloads'),
      content: const Text('音檔下載會保存到裝置本地端。下載完成後，詞目與例句音檔都可以在沒有網路的情況下播放。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
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

  List<DictionaryEntry> search(
    DictionaryBundle bundle,
    SearchDirection direction,
    String rawQuery,
  ) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
    }

    final scored = <_ScoredEntry>[];
    for (final entry in bundle.entries) {
      final score = _scoreEntry(entry, direction, query);
      if (score > 0) {
        scored.add(_ScoredEntry(entry, score));
      }
    }

    scored.sort((left, right) {
      final compareScore = right.score.compareTo(left.score);
      if (compareScore != 0) {
        return compareScore;
      }
      return left.entry.id.compareTo(right.entry.id);
    });

    return scored.take(60).map((item) => item.entry).toList(growable: false);
  }

  int _scoreEntry(
    DictionaryEntry entry,
    SearchDirection direction,
    String query,
  ) {
    if (direction == SearchDirection.hokkienToMandarin) {
      var bestScore = _scoreMatch(entry.hokkienSearch, query);
      bestScore = _maxScore(
        bestScore,
        _scoreWithBonus(normalizeQuery(entry.hanji), query, 80),
      );
      bestScore = _maxScore(
        bestScore,
        _scoreWithBonus(normalizeQuery(entry.romanization), query, 90),
      );
      return bestScore;
    }

    var bestScore = _scoreMatch(entry.mandarinSearch, query);
    for (final sense in entry.senses) {
      bestScore = _maxScore(
        bestScore,
        _scoreWithBonus(normalizeQuery(sense.definition), query, 70),
      );
      for (final example in sense.examples) {
        bestScore = _maxScore(
          bestScore,
          _scoreWithBonus(normalizeQuery(example.mandarin), query, 35),
        );
      }
    }
    return bestScore;
  }

  int _scoreWithBonus(String haystack, String query, int bonus) {
    final score = _scoreMatch(haystack, query);
    if (score <= 0) {
      return score;
    }
    return score + bonus;
  }

  int _maxScore(int current, int next) {
    return next > current ? next : current;
  }

  int _scoreMatch(String haystack, String query) {
    if (haystack.isEmpty || query.isEmpty) {
      return -1;
    }
    if (haystack == query) {
      return 450;
    }
    if (haystack.startsWith(query)) {
      return 320;
    }
    if (haystack.contains(' $query ')) {
      return 280;
    }
    if (haystack.contains(query)) {
      return 180;
    }
    return -1;
  }
}

class _ScoredEntry {
  const _ScoredEntry(this.entry, this.score);

  final DictionaryEntry entry;
  final int score;
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
  var normalized = input.trim().toLowerCase();
  for (final entry in _romanizationFold.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  normalized = normalized.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  normalized = normalized.replaceAll('o͘', 'oo');
  normalized = normalized.replaceAll('ⁿ', 'n');
  normalized = normalized.replaceAll(RegExp(r'[-_/]'), ' ');
  normalized = normalized.replaceAll(RegExp("[【】\\[\\]（）()、,.;:!?\"'`]+"), ' ');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
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
