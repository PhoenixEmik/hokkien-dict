import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/bookmarks/application/bookmark_store.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/dictionary/presentation/widgets/word_detail_sections.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:hokkien_dictionary/offline_audio.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _shareEntry(AppLocalizations l10n) async {
    final shareText = _buildShareText(entry, l10n);
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
            );
          },
        );

        if (isApplePlatform(context)) {
          final title = entry.hanji.isEmpty
              ? l10n.wordDetailFallbackTitle
              : entry.hanji;
          final tint = resolveLiquidGlassTint(context);
          final topPadding =
              MediaQuery.of(context).padding.top + kToolbarHeight + 16;
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: resolveLiquidGlassForeground(context),
                ),
              ),
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(CupertinoIcons.back, color: tint, size: 22),
              ),
              actions: [
                IconButton(
                  tooltip: l10n.shareEntry,
                  onPressed: () {
                    unawaited(_shareEntry(l10n));
                  },
                  icon: Icon(CupertinoIcons.share, color: tint, size: 21),
                ),
                IconButton(
                  tooltip: isBookmarked
                      ? l10n.removeBookmark
                      : l10n.addBookmark,
                  onPressed: () {
                    unawaited(bookmarkStore.toggleBookmark(entry.id));
                  },
                  icon: Icon(
                    isBookmarked
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    color: tint,
                    size: 21,
                  ),
                ),
              ],
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            body: LiquidGlassBackground(
              child: WordDetailBody(
                entry: entry,
                audioLibrary: audioLibrary,
                onPlayClip: onPlayClip,
                onWordTapped: onWordTapped,
                topPadding: topPadding,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              entry.hanji.isEmpty ? l10n.wordDetailFallbackTitle : entry.hanji,
            ),
            actions: [
              IconButton(
                tooltip: l10n.shareEntry,
                onPressed: () {
                  unawaited(_shareEntry(l10n));
                },
                icon: const Icon(Icons.share),
              ),
              IconButton(
                tooltip: isBookmarked ? l10n.removeBookmark : l10n.addBookmark,
                onPressed: () {
                  unawaited(bookmarkStore.toggleBookmark(entry.id));
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

String _buildShareText(DictionaryEntry entry, AppLocalizations l10n) {
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
    this.topPadding = 12,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isApplePlatform(context) ? 16 : 20,
                  topPadding,
                  isApplePlatform(context) ? 16 : 20,
                  isApplePlatform(context) ? 34 : 24,
                ),
                children: [
                  SelectionArea(
                    child: _WordDetailContent(
                      entry: entry,
                      audioLibrary: audioLibrary,
                      onPlayClip: onPlayClip,
                      onWordTapped: onWordTapped,
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
      ),
    );
  }
}

class _WordDetailContent extends StatelessWidget {
  const _WordDetailContent({
    required this.entry,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.onWordTapped,
    required this.readingTextScale,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
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
      ],
    );
  }
}
