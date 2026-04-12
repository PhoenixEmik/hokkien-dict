import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/bookmarks/application/bookmark_store.dart';
import 'package:taigi_dict/features/bookmarks/presentation/widgets/bookmark_empty_state.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_repository.dart';
import 'package:taigi_dict/features/dictionary/domain/dictionary_models.dart';
import 'package:taigi_dict/features/dictionary/presentation/coordinators/word_detail_coordinator.dart';
import 'package:taigi_dict/features/dictionary/presentation/widgets/entry_list_item.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/offline_audio.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.repository,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onActionResult,
    this.showOwnScaffold = true,
  });

  final DictionaryRepository repository;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final ValueChanged<AudioActionResult> onActionResult;
  final bool showOwnScaffold;

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

  Future<void> _showEntryDetails(
    DictionaryBundle bundle,
    DictionaryEntry entry,
  ) async {
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
    final l10n = AppLocalizations.of(context);
    final applePlatform = isApplePlatform(context);

    return AnimatedBuilder(
      animation: widget.bookmarkStore,
      builder: (context, child) {
        final content = FutureBuilder<DictionaryBundle>(
          future: _bundleFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.loadDataFailed('${snapshot.error}'),
                    style: Theme.of(context).textTheme.titleMedium,
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

            final bookmarkedEntries = _buildBookmarkedEntries(snapshot.data!);
            return LiquidGlassBackground(
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                        ),
                        child: bookmarkedContent(
                          bookmarkedEntries,
                          snapshot.data!,
                          applePlatform,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );

        if (!widget.showOwnScaffold) {
          return content;
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.bookmarksTitle)),
          body: content,
        );
      },
    );
  }

  Widget bookmarkedContent(
    List<DictionaryEntry> bookmarkedEntries,
    DictionaryBundle bundle,
    bool applePlatform,
  ) {
    if (bookmarkedEntries.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          applePlatform ? 24 : 16,
          16,
          applePlatform ? 140 : 28,
        ),
        child: const BookmarkEmptyState(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        applePlatform ? 12 : 16,
        16,
        applePlatform ? 140 : 28,
      ),
      itemCount: bookmarkedEntries.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == bookmarkedEntries.length - 1 ? 0 : 10,
          ),
          child: SelectionArea(
            child: EntryListItem(
              entry: bookmarkedEntries[index],
              onTap: () => _showEntryDetails(bundle, bookmarkedEntries[index]),
            ),
          ),
        );
      },
    );
  }
}
