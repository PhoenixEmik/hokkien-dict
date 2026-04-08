import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DictionaryRepository _repository = DictionaryRepository();
  final OfflineAudioLibrary _audioLibrary = OfflineAudioLibrary();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
  }

  @override
  void dispose() {
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
    required this.onActionResult,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final ValueChanged<AudioActionResult> onActionResult;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<DictionaryBundle> _bundleFuture;

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
      _filteredResults = _buildFilteredResults(bundle, _searchController.text);
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(
          entry: entry,
          audioLibrary: widget.audioLibrary,
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
                            onQueryChanged: (_) => _handleQueryChanged(),
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
    return AnimatedBuilder(
      animation: audioLibrary,
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      SettingsSectionHeader(
                        title: '離線資源',
                        subtitle:
                            '${AudioArchiveType.values.where(audioLibrary.isArchiveReady).length} / 2 套資源已就緒',
                      ),
                      AudioResourceTile(
                        type: AudioArchiveType.word,
                        audioLibrary: audioLibrary,
                        onDownload: onDownloadArchive,
                      ),
                      const Divider(height: 1, indent: 72),
                      AudioResourceTile(
                        type: AudioArchiveType.sentence,
                        audioLibrary: audioLibrary,
                        onDownload: onDownloadArchive,
                      ),
                      const Divider(height: 32),
                      const SettingsSectionHeader(
                        title: '關於',
                        subtitle: '查看應用程式資訊與開源授權。',
                      ),
                      SettingsNavigationTile(
                        icon: Icons.info_outline,
                        title: '關於',
                        subtitle: '了解台語辭典的用途、資料來源與授權。',
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => const AppAboutDialog(),
                        ),
                      ),
                      const Divider(height: 1, indent: 72),
                      SettingsNavigationTile(
                        icon: Icons.code_outlined,
                        title: '開源授權',
                        subtitle: '查看應用程式與相依套件的授權資訊。',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  const OpenSourceCreditsPage(),
                            ),
                          );
                        },
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

class SearchWorkspaceCard extends StatelessWidget {
  const SearchWorkspaceCard({
    super.key,
    required this.controller,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: controller,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: '輸入台語漢字、白話字或華語詞義',
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
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18363C),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF17454C)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF18363C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5A6D71),
          height: 1.4,
        ),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF708286)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({
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
    return Scaffold(
      appBar: AppBar(title: Text(entry.hanji.isEmpty ? '詞條詳細資料' : entry.hanji)),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        '顯示符合查詢的台語詞目與華語義項',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF617176),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('關於台語辭典'),
      content: const Text(
        '台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。\n\n'
        'App code: MIT\n'
        'Dictionary data and audio: 教育部《臺灣台語常用詞辭典》衍生內容，採 CC BY-NC-ND 2.5 TW。\n\n'
        '參考頁面：https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

class OpenSourceCreditsPage extends StatelessWidget {
  const OpenSourceCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開源授權')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    const CreditSectionCard(
                      title: 'Application',
                      body:
                          '台語辭典 app code is distributed under the MIT license.',
                    ),
                    const SizedBox(height: 12),
                    const CreditSectionCard(
                      title: 'Dictionary data and audio',
                      body:
                          'Bundled dictionary data and downloaded audio are derived from the Ministry of Education 臺灣台語常用詞辭典 dataset and remain separately licensed under CC BY-NC-ND 2.5 TW.',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: SettingsNavigationTile(
                        icon: Icons.description_outlined,
                        title: '套件授權',
                        subtitle: '查看 Flutter 與相依套件附帶的授權聲明。',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const LicensePage(
                                applicationName: '台語辭典',
                                applicationLegalese:
                                    'App code: MIT. Dictionary data and audio are separately licensed.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CreditSectionCard extends StatelessWidget {
  const CreditSectionCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18363C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioAboutDialog extends StatelessWidget {
  const AudioAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About Audio Downloads'),
      content: const Text(
        '音檔下載會保存到裝置本地端。下載完成後，詞目與例句音檔都可以在沒有網路的情況下播放。\n\n'
        '詞目與例句音檔來源：教育部《臺灣台語常用詞辭典》\n'
        '參考頁面：https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
      ),
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

  List<DictionaryEntry> search(DictionaryBundle bundle, String rawQuery) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const [];
    }

    final matched = <_ScoredEntry>[];
    for (final entry in bundle.entries) {
      final headword = _headwordForSearch(entry);
      final priority = _matchPriority(headword, query);
      if (priority != null) {
        matched.add(_ScoredEntry(entry, priority));
      }
    }

    matched.sort((left, right) {
      final comparePriority = left.score.compareTo(right.score);
      if (comparePriority != 0) {
        return comparePriority;
      }

      final leftHeadword = _headwordForSearch(left.entry);
      final rightHeadword = _headwordForSearch(right.entry);
      final compareLength = leftHeadword.length.compareTo(rightHeadword.length);
      if (compareLength != 0) {
        return compareLength;
      }

      return left.entry.id.compareTo(right.entry.id);
    });

    return matched.take(60).map((item) => item.entry).toList(growable: false);
  }

  String _headwordForSearch(DictionaryEntry entry) {
    final headword = entry.hanji.isNotEmpty ? entry.hanji : entry.romanization;
    return normalizeQuery(headword);
  }

  int? _matchPriority(String headword, String query) {
    if (headword.isEmpty || query.isEmpty || !headword.contains(query)) {
      return null;
    }
    if (headword == query) {
      return 0;
    }
    if (headword.startsWith(query)) {
      return 1;
    }
    return 2;
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
