import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../features/bookmarks/application/bookmark_store.dart';
import '../../../../offline_audio.dart';
import '../../application/dictionary_search_controller.dart';
import '../../data/dictionary_repository.dart';
import '../../domain/dictionary_models.dart';
import '../widgets/entry_list_item.dart';
import '../widgets/search_panel.dart';
import 'word_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = DictionarySearchController(
      repository: widget.repository,
    )..initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _playClip(AudioArchiveType type, String clipId) async {
    final result = await widget.audioLibrary.playClip(type, clipId);
    widget.onActionResult(result);
  }

  Future<void> _showEntryDetails(DictionaryEntry entry) async {
    await _searchController.saveCurrentQueryIfNeeded();
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

            final query = _searchController.searchController.text;
            final hasActiveQuery = _searchController.normalizedQuery.isNotEmpty;
            final filteredResults = _searchController.filteredResults;
            final isSearching = _searchController.isSearching;
            final searchHistory = _searchController.searchHistory;

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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                            sliver: !hasActiveQuery
                                ? SliverToBoxAdapter(
                                    child: EmptyState(query: query),
                                  )
                                : isSearching
                                ? const SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: 220,
                                      child: SearchLoadingState(),
                                    ),
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
      },
    );
  }
}
