import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/translation/chinese_translation_service.dart';
import 'package:taigi_dict/features/bookmarks/application/bookmark_store.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_repository.dart';
import 'package:taigi_dict/features/dictionary/domain/dictionary_models.dart';
import 'package:taigi_dict/features/dictionary/presentation/screens/word_detail_screen.dart';
import 'package:taigi_dict/offline_audio.dart';

class WordDetailCoordinator {
  const WordDetailCoordinator._();

  static Future<void> playClip({
    required OfflineAudioLibrary audioLibrary,
    required AudioArchiveType type,
    required String clipId,
    required AppLocalizations l10n,
    required ValueChanged<AudioActionResult> onActionResult,
  }) async {
    final result = await audioLibrary.playClip(type, clipId, l10n);
    onActionResult(result);
  }

  static Future<void> showWordDetail({
    required BuildContext context,
    required DictionaryEntry entry,
    required DictionaryRepository repository,
    required DictionaryBundle bundle,
    required OfflineAudioLibrary audioLibrary,
    required BookmarkStore bookmarkStore,
    required ValueChanged<AudioActionResult> onActionResult,
  }) async {
    final resolvedLocale = AppLocalizations.resolveLocale(
      Localizations.localeOf(context),
    );
    final translationService = ChineseTranslationService.instance;
    final sourceEntry = bundle.entries
        .where((candidate) {
          return candidate.id == entry.id;
        })
        .fold<DictionaryEntry?>(null, (previous, candidate) {
          return previous ?? candidate;
        });
    final localizedEntry = await translationService.translateEntryForDisplay(
      sourceEntry ?? entry,
      locale: resolvedLocale,
    );
    if (!context.mounted) {
      return;
    }

    Future<void> onPlayClip(AudioArchiveType type, String clipId) {
      return playClip(
        audioLibrary: audioLibrary,
        type: type,
        clipId: clipId,
        l10n: AppLocalizations.of(context),
        onActionResult: onActionResult,
      );
    }

    Future<void> onWordTapped(String word) async {
      final normalizedLookupWord = await translationService
          .normalizeSearchInput(word, locale: resolvedLocale);
      if (!context.mounted) {
        return;
      }
      final linkedEntry = repository.findLinkedEntry(
        bundle,
        normalizedLookupWord,
      );
      if (linkedEntry == null) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.linkedEntryNotFound(word))));
        return;
      }

      await showWordDetail(
        context: context,
        entry: linkedEntry,
        repository: repository,
        bundle: bundle,
        audioLibrary: audioLibrary,
        bookmarkStore: bookmarkStore,
        onActionResult: onActionResult,
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(
          entry: localizedEntry,
          audioLibrary: audioLibrary,
          bookmarkStore: bookmarkStore,
          onPlayClip: onPlayClip,
          onWordTapped: onWordTapped,
        ),
      ),
    );
  }
}
