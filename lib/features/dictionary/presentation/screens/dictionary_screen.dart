import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/bookmarks/application/bookmark_store.dart';
import 'package:taigi_dict/features/dictionary/application/dictionary_search_controller.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_repository.dart';
import 'package:taigi_dict/features/dictionary/domain/dictionary_models.dart';
import 'package:taigi_dict/features/dictionary/presentation/coordinators/word_detail_coordinator.dart';
import 'package:taigi_dict/features/dictionary/presentation/widgets/entry_list_item.dart';
import 'package:taigi_dict/features/dictionary/presentation/widgets/search_panel.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/offline_audio.dart';

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
  late final DictionarySearchController _searchController;
  late final ScrollController _scrollController;
  Locale? _lastResolvedLocale;
  int _searchBarVersion = 0;
  bool _requestSearchAutofocus = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _focusSearchField() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {
      _searchBarVersion += 1;
      _requestSearchAutofocus = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requestSearchAutofocus = false;
      });
    });
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final applePlatform = isApplePlatform(context);

    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, child) {
        return FutureBuilder<DictionaryBundle>(
          future: _searchController.bundleFuture,
          builder: (context, snapshot) {
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

            if (!snapshot.hasData) {
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
            final showAppleStartSearchFab =
                applePlatform && !hasActiveQuery && !isSearching;

            final content = LiquidGlassBackground(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                        ),
                        child: CustomScrollView(
                          controller: _scrollController,
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
                                  key: ValueKey(
                                    'search-bar-$_searchBarVersion',
                                  ),
                                  controller:
                                      _searchController.searchController,
                                  autofocus: _requestSearchAutofocus,
                                  onSubmitted: (_) {
                                    unawaited(_searchController.submitQuery());
                                  },
                                ),
                              ),
                            ),
                            if (!hasActiveQuery && searchHistory.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
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
                                showAppleStartSearchFab ? 112 : 28,
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
                                              snapshot.data!,
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
              ),
            );

            if (applePlatform) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: content,
                floatingActionButton: showAppleStartSearchFab
                    ? AppleSearchFloatingButton(
                        label: l10n.startSearch,
                        onTap: _focusSearchField,
                      )
                    : null,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
              );
            }

            return content;
          },
        );
      },
    );
  }
}
