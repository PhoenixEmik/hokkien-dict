import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/bookmarks/bookmarks.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

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

class _BookmarksScreenState extends State<BookmarksScreen>
    with AutomaticKeepAliveClientMixin {
  late final Future<DictionaryBundle> _bundleFuture;
  Future<List<DictionaryEntry>>? _entriesFuture;
  String _entriesFutureKey = '';
  DictionaryBundle? _cachedBundle;
  final Map<String, List<DictionaryEntry>> _entriesCacheByKey =
      <String, List<DictionaryEntry>>{};
  Locale _displayLocale = AppLocalizations.traditionalChineseLocale;
  final ChineseTranslationService _translationService =
      ChineseTranslationService.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bundleFuture = widget.repository.loadBundle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolvedLocale = AppLocalizations.resolveLocale(
      Localizations.localeOf(context),
    );
    if (_displayLocale == resolvedLocale) {
      return;
    }
    _displayLocale = resolvedLocale;
    _entriesFuture = null;
    _entriesFutureKey = '';
    _entriesCacheByKey.clear();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;

    return AnimatedBuilder(
      animation: widget.bookmarkStore,
      builder: (context, child) {
        final content = FutureBuilder<DictionaryBundle>(
          future: _bundleFuture,
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
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (bundle == null) {
              return Center(
                child: const CircularProgressIndicator(),
              );
            }

            final bookmarkedIds = widget.bookmarkStore.bookmarkedIds
                .toList(growable: false)
              ..sort();
            if (bookmarkedIds.isEmpty) {
              return bookmarkedContent(
                const [],
                bundle,
              );
            }

            final entriesFutureKey =
                '${bookmarkedIds.join(',')}_${_displayLocale.toLanguageTag()}';
            if (_entriesFuture == null ||
                _entriesFutureKey != entriesFutureKey) {
              _entriesFutureKey = entriesFutureKey;
              _entriesFuture = widget.repository
                  .entriesByIdsAsync(bundle, bookmarkedIds)
                  .then(
                    (entries) =>
                        _translationService.translateEntriesForSearchResults(
                          entries,
                          locale: _displayLocale,
                        ),
                  );
            }

            final cachedEntries = _entriesCacheByKey[entriesFutureKey];

            return FutureBuilder<List<DictionaryEntry>>(
              future: _entriesFuture,
              builder: (context, entriesSnapshot) {
                if (entriesSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.loadDataFailed('${entriesSnapshot.error}'),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (entriesSnapshot.hasData) {
                  _entriesCacheByKey[entriesFutureKey] = entriesSnapshot.data!;
                }

                final resolvedEntries =
                    entriesSnapshot.data ?? cachedEntries;

                if (resolvedEntries == null) {
                  return Center(
                    child: const CircularProgressIndicator(),
                  );
                }

                return bookmarkedContent(
                  resolvedEntries,
                  bundle,
                );
              },
            );
          },
        );

        if (!widget.showOwnScaffold) {
          return content;
        }

        return AdaptiveScaffold(
          appBar: AdaptiveAppBar(
            title: l10n.bookmarksTitle,
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

  Widget bookmarkedContent(
    List<DictionaryEntry> bookmarkedEntries,
    DictionaryBundle bundle,
  ) {
    final bottomInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16
        : 16.0;

    if (bookmarkedEntries.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: const BookmarkEmptyState(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
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
