import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'dart:async';
import 'package:flutter/material.dart';
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
  late final DictionarySearchController _searchController;
  Locale? _lastResolvedLocale;
  DictionaryBundle? _cachedBundle;

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final platform = Theme.of(context).platform;
    final applePlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final topBodyInset = PlatformInfo.isIOS
      ? MediaQuery.paddingOf(context).top + kToolbarHeight
      : 0.0;
    final bottomContentPadding = platform == TargetPlatform.iOS
      ? MediaQuery.paddingOf(context).bottom + 88
      : 28.0;

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
              return Center(
                child: applePlatform
                    ? const CircularProgressIndicator.adaptive()
                    : const CircularProgressIndicator(),
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
                              applePlatform ? 12 : 16,
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

        return AdaptiveScaffold(
          appBar: AdaptiveAppBar(
            title: l10n.dictionaryTab,
            useNativeToolbar: true,
          ),
          extendBodyBehindAppBar: false,
          useHeroBackButton: false,
          body: Padding(
            padding: EdgeInsets.only(top: topBodyInset),
            child: content,
          ),
        );
      },
    );
  }
}
