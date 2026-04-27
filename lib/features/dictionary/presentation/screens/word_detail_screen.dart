import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/bookmarks/bookmarks.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.bookmarkStore,
    required this.onPlayClip,
    required this.onWordTapped,
    required this.canOpenWord,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final BookmarkStore bookmarkStore;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final bool Function(String word) canOpenWord;

  Future<void> _shareEntry(AppLocalizations l10n) async {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bookmarkStore,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);
        final isBookmarked = bookmarkStore.isBookmarked(entry.id);
        final body = AnimatedBuilder(
          animation: audioLibrary,
          builder: (context, child) {
            return WordDetailBody(
              entry: entry,
              audioLibrary: audioLibrary,
              onPlayClip: onPlayClip,
              onWordTapped: onWordTapped,
              canOpenWord: canOpenWord,
            );
          },
        );

        final topBodyInset = PlatformInfo.isIOS
            ? MediaQuery.paddingOf(context).top + kToolbarHeight
            : 0.0;

        return AdaptiveScaffold(
          appBar: AdaptiveAppBar(
            title: entry.hanji.isEmpty
                ? l10n.wordDetailFallbackTitle
                : entry.hanji,
            useNativeToolbar: true,
            tintColor: Theme.of(context).colorScheme.primary,
            actions: [
              AdaptiveAppBarAction(
                iosSymbol: 'square.and.arrow.up',
                icon: Icons.share,
                onPressed: () {
                  unawaited(_shareEntry(l10n));
                },
              ),
              AdaptiveAppBarAction(
                iosSymbol: isBookmarked ? 'bookmark.fill' : 'bookmark',
                icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                onPressed: () {
                  unawaited(bookmarkStore.toggleBookmark(entry.id));
                },
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.only(top: topBodyInset),
            child: body,
          ),
        );
      },
    );
  }
}

String buildShareTextForEntry(DictionaryEntry entry, AppLocalizations l10n) {
  final word = entry.hanji.trim().isEmpty
      ? l10n.unlabeledHanji
      : entry.hanji.trim();
  final romanization = entry.romanization.trim();
  final definitions = entry.senses
      .map((sense) => sense.definition.trim())
      .where((definition) => definition.isNotEmpty)
      .toList(growable: false);

  final buffer = StringBuffer()..write('【$word】');
  if (romanization.isNotEmpty) {
    buffer.write('($romanization)');
  }

  if (definitions.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(definitions.join('\n'));
  } else if (entry.briefSummary.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(entry.briefSummary.trim());
  }

  buffer
    ..writeln()
    ..write(l10n.shareEntryFooter);
  return buffer.toString().trim();
}

class WordDetailBody extends StatelessWidget {
  const WordDetailBody({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.onWordTapped,
    required this.canOpenWord,
    this.maxContentWidth,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final bool Function(String word) canOpenWord;
  final double? maxContentWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedMaxWidth =
            maxContentWidth ?? (constraints.maxWidth >= 900 ? 920.0 : 720.0);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
            child: ListView(
              padding: padding,
              children: [
                SelectionArea(
                  child: _WordDetailContent(
                    entry: entry,
                    audioLibrary: audioLibrary,
                    onPlayClip: onPlayClip,
                    onWordTapped: onWordTapped,
                    canOpenWord: canOpenWord,
                    readingTextScale: AppPreferencesScope.of(
                      context,
                    ).readingTextScale,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WordDetailContent extends StatelessWidget {
  const _WordDetailContent({
    required this.entry,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.onWordTapped,
    required this.canOpenWord,
    required this.readingTextScale,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final bool Function(String word) canOpenWord;
  final double readingTextScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WordDetailHeader(
          entry: entry,
          audioLibrary: audioLibrary,
          onPlayClip: onPlayClip,
          onWordTapped: onWordTapped,
          canOpenWord: canOpenWord,
        ),
        const SizedBox(height: 20),
        ...entry.senses.map((sense) {
          return SenseSection(
            sense: sense,
            audioLibrary: audioLibrary,
            onPlayClip: onPlayClip,
            onWordTapped: onWordTapped,
            canOpenWord: canOpenWord,
            textScale: readingTextScale,
          );
        }),
        if (entry.phoneticDifferences.isNotEmpty)
          DetailNoteCard(
            title: AppLocalizations.of(context).phoneticDifferencesLabel,
            lines: entry.phoneticDifferences,
          ),
        if (entry.vocabularyComparisons.isNotEmpty)
          DetailNoteCard(
            title: AppLocalizations.of(context).vocabularyComparisonLabel,
            lines: entry.vocabularyComparisons,
          ),
      ],
    );
  }
}
