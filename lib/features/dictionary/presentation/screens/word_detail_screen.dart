import 'dart:async';

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
          final secondaryTint = resolveLiquidGlassSecondaryTint(
            context,
          ).withValues(alpha: 0.72);
          final tint = resolveLiquidGlassTint(context);
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: secondaryTint,
              border: null,
              middle: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: resolveLiquidGlassForeground(context),
                ),
              ),
              leading: CupertinoNavigationBarBackButton(
                color: tint,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
                    onPressed: () {
                      unawaited(_shareEntry(l10n));
                    },
                    child: Icon(CupertinoIcons.share, color: tint, size: 21),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
                    onPressed: () {
                      unawaited(bookmarkStore.toggleBookmark(entry.id));
                    },
                    child: Icon(
                      isBookmarked
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color: tint,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
            child: LiquidGlassBackground(child: body),
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
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;

  @override
  Widget build(BuildContext context) {
    final readingTextScale = AppPreferencesScope.of(context).readingTextScale;
    final applePlatform = isApplePlatform(context);

    return SafeArea(
      top: !applePlatform,
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
                  applePlatform ? 16 : 20,
                  applePlatform ? 72 : 12,
                  applePlatform ? 16 : 20,
                  applePlatform ? 34 : 24,
                ),
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
