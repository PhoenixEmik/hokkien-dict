import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/bookmarks/bookmarks.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({
    super.key,
    required this.repository,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onActionResult,
    this.showOwnScaffold = false,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final ValueChanged<AudioActionResult> onActionResult;
  final bool showOwnScaffold;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen>
    with AutomaticKeepAliveClientMixin {
  static const double _tabletBreakpoint = 960;
  static const double _tabletMaxContentWidth = 1480;
  static const double _tabletPaneGap = 20;

  late final DictionarySearchController _searchController;
  Locale? _lastResolvedLocale;
  DictionaryBundle? _cachedBundle;
  DictionaryEntry? _selectedTabletSourceEntry;
  PreparedWordDetail? _selectedTabletDetail;
  bool _isLoadingTabletDetail = false;
  int _tabletSelectionToken = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = DictionarySearchController(
      repository: widget.repository,
    )..initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolvedLocale = AppLocalizations.resolveLocale(
      Localizations.localeOf(context),
    );
    if (_lastResolvedLocale == resolvedLocale) {
      return;
    }
    _lastResolvedLocale = resolvedLocale;
    _searchController.updateDisplayLocale(resolvedLocale);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEntryDetails(
    DictionaryBundle bundle,
    DictionaryEntry entry,
  ) async {
    await _searchController.saveCurrentQueryIfNeeded();
    if (!mounted) {
      return;
    }
    await WordDetailCoordinator.showWordDetail(
      context: context,
      entry: entry,
      repository: widget.repository,
      bundle: bundle,
      audioLibrary: widget.audioLibrary,
      bookmarkStore: widget.bookmarkStore,
      onActionResult: widget.onActionResult,
    );
  }

  Future<void> _selectTabletEntry(
    DictionaryBundle bundle,
    DictionaryEntry entry,
  ) async {
    final token = ++_tabletSelectionToken;
    setState(() {
      _selectedTabletSourceEntry = entry;
      _isLoadingTabletDetail = true;
    });

    final prepared = await WordDetailCoordinator.prepareWordDetail(
      context: context,
      entry: entry,
      repository: widget.repository,
      bundle: bundle,
    );
    if (!mounted || token != _tabletSelectionToken) {
      return;
    }

    setState(() {
      _selectedTabletDetail = prepared;
      _isLoadingTabletDetail = false;
    });
  }

  Future<void> _openLinkedTabletEntry(
    DictionaryBundle bundle,
    PreparedWordDetail detail,
    String word,
  ) async {
    final linkedEntry = await WordDetailCoordinator.findNavigableLinkedEntry(
      context: context,
      repository: widget.repository,
      bundle: bundle,
      currentEntryId: detail.resolvedEntryId,
      word: word,
    );
    if (!mounted) {
      return;
    }

    if (linkedEntry == null) {
      widget.onActionResult(
        AudioActionResult(
          message: AppLocalizations.of(context).linkedEntryNotFound(word),
          isError: true,
        ),
      );
      return;
    }

    await _selectTabletEntry(bundle, linkedEntry);
  }

  Future<void> _shareTabletEntry(DictionaryEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final shareText = buildShareTextForEntry(entry, l10n);
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        title: entry.hanji.isEmpty ? l10n.shareEntryTitleFallback : entry.hanji,
        subject: entry.hanji.isEmpty
            ? l10n.shareEntryTitleFallback
            : entry.hanji,
      ),
    );
  }

  bool _shouldUseTabletLayout(BoxConstraints constraints) =>
      constraints.maxWidth >= _tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomContentPadding = MediaQuery.paddingOf(context).bottom + 28;

    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, child) {
        final content = FutureBuilder<DictionaryBundle>(
          future: _searchController.bundleFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _cachedBundle = snapshot.data;
            }
            final bundle = snapshot.data ?? _cachedBundle;

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.loadDataFailed('${snapshot.error}'),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (bundle == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final query = _searchController.searchController.text;
            final hasActiveQuery = _searchController.normalizedQuery.isNotEmpty;
            final filteredResults = _searchController.filteredResults;
            final isSearching = _searchController.isSearching;
            final searchHistory = _searchController.searchHistory;

            return SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useTabletLayout = _shouldUseTabletLayout(constraints);
                  if (!hasActiveQuery &&
                      (_selectedTabletSourceEntry != null ||
                          _selectedTabletDetail != null ||
                          _isLoadingTabletDetail)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _selectedTabletSourceEntry = null;
                        _selectedTabletDetail = null;
                        _isLoadingTabletDetail = false;
                      });
                    });
                  }

                  if (useTabletLayout) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _tabletMaxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            16,
                            20,
                            bottomContentPadding,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 4,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: _TabletSearchPane(
                                    hasActiveQuery: hasActiveQuery,
                                    isSearching: isSearching,
                                    query: query,
                                    filteredResults: filteredResults,
                                    searchHistory: searchHistory,
                                    searchController: _searchController,
                                    selectedEntryId:
                                        _selectedTabletSourceEntry?.id,
                                    onEntryTap: (entry) {
                                      unawaited(
                                        _selectTabletEntry(bundle, entry),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: _tabletPaneGap),
                              Expanded(
                                flex: 6,
                                child: _TabletDetailPane(
                                  bundle: bundle,
                                  detail: _selectedTabletDetail,
                                  bookmarkStore: widget.bookmarkStore,
                                  audioLibrary: widget.audioLibrary,
                                  isLoading: _isLoadingTabletDetail,
                                  onPlayClip: (type, clipId) =>
                                      WordDetailCoordinator.playClip(
                                        audioLibrary: widget.audioLibrary,
                                        type: type,
                                        clipId: clipId,
                                        l10n: AppLocalizations.of(context),
                                        onActionResult: widget.onActionResult,
                                      ),
                                  onWordTapped: (word) async {
                                    final detail = _selectedTabletDetail;
                                    if (detail == null) {
                                      return;
                                    }
                                    await _openLinkedTabletEntry(
                                      bundle,
                                      detail,
                                      word,
                                    );
                                  },
                                  onShare: _shareTabletEntry,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

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
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              12,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: SearchWorkspaceCard(
                                controller: _searchController.searchController,
                                onSubmitted: (_) {
                                  unawaited(_searchController.submitQuery());
                                },
                              ),
                            ),
                          ),
                          if (!hasActiveQuery && searchHistory.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              sliver: SliverToBoxAdapter(
                                child: SearchHistorySection(
                                  history: searchHistory,
                                  onHistoryTap:
                                      _searchController.applyHistoryQuery,
                                  onClearHistory:
                                      _searchController.clearSearchHistory,
                                ),
                              ),
                            ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              bottomContentPadding,
                            ),
                            sliver: !hasActiveQuery
                                ? SliverToBoxAdapter(
                                    child: SelectionArea(
                                      child: EmptyState(query: query),
                                    ),
                                  )
                                : isSearching
                                ? const SliverToBoxAdapter(
                                    child: SearchLoadingState(),
                                  )
                                : filteredResults.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: NoResultsState(),
                                  )
                                : SliverList.separated(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      return SelectionArea(
                                        child: EntryListItem(
                                          entry: filteredResults[index],
                                          onTap: () => _showEntryDetails(
                                            bundle,
                                            filteredResults[index],
                                          ),
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

        if (!widget.showOwnScaffold) {
          return content;
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.dictionaryTab)),
          body: content,
        );
      },
    );
  }
}

class _TabletSearchPane extends StatelessWidget {
  const _TabletSearchPane({
    required this.hasActiveQuery,
    required this.isSearching,
    required this.query,
    required this.filteredResults,
    required this.searchHistory,
    required this.searchController,
    required this.selectedEntryId,
    required this.onEntryTap,
  });

  final bool hasActiveQuery;
  final bool isSearching;
  final String query;
  final List<DictionaryEntry> filteredResults;
  final List<String> searchHistory;
  final DictionarySearchController searchController;
  final int? selectedEntryId;
  final ValueChanged<DictionaryEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: SearchWorkspaceCard(
            controller: searchController.searchController,
            onSubmitted: (_) {
              unawaited(searchController.submitQuery());
            },
          ),
        ),
        if (!hasActiveQuery && searchHistory.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(top: 12),
            sliver: SliverToBoxAdapter(
              child: SearchHistorySection(
                history: searchHistory,
                onHistoryTap: searchController.applyHistoryQuery,
                onClearHistory: searchController.clearSearchHistory,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 12),
          sliver: !hasActiveQuery
              ? SliverToBoxAdapter(
                  child: SelectionArea(child: EmptyState(query: query)),
                )
              : isSearching
              ? const SliverToBoxAdapter(child: SearchLoadingState())
              : filteredResults.isEmpty
              ? const SliverToBoxAdapter(child: NoResultsState())
              : SliverList.separated(
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final entry = filteredResults[index];
                    return SelectionArea(
                      child: EntryListItem(
                        entry: entry,
                        selected: selectedEntryId == entry.id,
                        onTap: () => onEntryTap(entry),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
                  },
                ),
        ),
      ],
    );
  }
}

class _TabletDetailPane extends StatelessWidget {
  const _TabletDetailPane({
    required this.bundle,
    required this.detail,
    required this.bookmarkStore,
    required this.audioLibrary,
    required this.isLoading,
    required this.onPlayClip,
    required this.onWordTapped,
    required this.onShare,
  });

  final DictionaryBundle bundle;
  final PreparedWordDetail? detail;
  final BookmarkStore bookmarkStore;
  final OfflineAudioLibrary audioLibrary;
  final bool isLoading;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final Future<void> Function(DictionaryEntry entry) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isLoading
          ? const SizedBox.expand(
              key: ValueKey('tablet-detail-loading'),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : detail == null
          ? SizedBox.expand(
              key: const ValueKey('tablet-detail-empty'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.tabletPreviewEmptyTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.tabletPreviewEmptyBody,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Column(
              key: ValueKey('tablet-detail-${detail!.resolvedEntryId}'),
              children: [
                _TabletDetailToolbar(
                  entry: detail!.entry,
                  bookmarkStore: bookmarkStore,
                  onShare: onShare,
                ),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([bookmarkStore, audioLibrary]),
                    builder: (context, child) {
                      return WordDetailBody(
                        entry: detail!.entry,
                        audioLibrary: audioLibrary,
                        onPlayClip: onPlayClip,
                        onWordTapped: onWordTapped,
                        canOpenWord: detail!.canOpenWord,
                        maxContentWidth: 860,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _TabletDetailToolbar extends StatelessWidget {
  const _TabletDetailToolbar({
    required this.entry,
    required this.bookmarkStore,
    required this.onShare,
  });

  final DictionaryEntry entry;
  final BookmarkStore bookmarkStore;
  final Future<void> Function(DictionaryEntry entry) onShare;

  @override
  Widget build(BuildContext context) {
    final isBookmarked = bookmarkStore.isBookmarked(entry.id);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.hanji.isEmpty ? l10n.wordDetailFallbackTitle : entry.hanji,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: l10n.shareEntry,
            child: SizedBox.square(
              dimension: 36,
              child: IconButton.filledTonal(
                onPressed: () {
                  unawaited(onShare(entry));
                },
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(36),
                  maximumSize: const Size.square(36),
                ),
                icon: const Icon(Icons.share),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: isBookmarked ? l10n.removeBookmark : l10n.addBookmark,
            child: SizedBox.square(
              dimension: 36,
              child: IconButton.filledTonal(
                onPressed: () {
                  unawaited(bookmarkStore.toggleBookmark(entry.id));
                },
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(36),
                  maximumSize: const Size.square(36),
                ),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
