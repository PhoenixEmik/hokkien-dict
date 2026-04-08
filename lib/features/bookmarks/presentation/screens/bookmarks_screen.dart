import 'package:flutter/material.dart';

import '../../../../offline_audio.dart';
import '../../../dictionary/data/dictionary_repository.dart';
import '../../../dictionary/domain/dictionary_models.dart';
import '../../../dictionary/presentation/screens/word_detail_screen.dart';
import '../../../dictionary/presentation/widgets/entry_list_item.dart';
import '../../application/bookmark_store.dart';
import '../widgets/bookmark_empty_state.dart';

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
