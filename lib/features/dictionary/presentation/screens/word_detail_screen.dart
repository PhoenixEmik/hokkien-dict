import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/bookmarks/application/bookmark_store.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/dictionary/presentation/widgets/word_detail_sections.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onPlayClip,
    required this.onWordTapped,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;

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
                onWordTapped: onWordTapped,
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
    required this.onWordTapped,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingTextScale = AppPreferencesScope.of(context).readingTextScale;

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
                  SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WordDetailHeader(
                          entry: entry,
                          audioLibrary: audioLibrary,
                          onPlayClip: onPlayClip,
                        ),
                        const SizedBox(height: 20),
                        ...entry.senses.map((sense) {
                          return SenseSection(
                            sense: sense,
                            audioLibrary: audioLibrary,
                            onPlayClip: onPlayClip,
                            onWordTapped: onWordTapped,
                            textScale: readingTextScale,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
