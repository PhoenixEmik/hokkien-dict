import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/bookmarks/bookmarks.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

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
    final resolvedEntry = await _resolveAliasEntry(
      repository: repository,
      bundle: bundle,
      entry: entry,
    );
    if (!context.mounted) {
      return;
    }

    final sourceEntry = bundle.isDatabaseBacked
        ? resolvedEntry
        : bundle.entries
              .where((candidate) {
                return candidate.id == resolvedEntry.id;
              })
              .fold<DictionaryEntry?>(null, (previous, candidate) {
                return previous ?? candidate;
              });
    final localizedEntry = await translationService.translateEntryForDisplay(
      sourceEntry ?? resolvedEntry,
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
      final linkedEntry = await repository.findLinkedEntryAsync(
        bundle,
        normalizedLookupWord,
      );
      if (!context.mounted) {
        return;
      }
      if (linkedEntry == null) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.linkedEntryNotFound(word))));
        return;
      }

      final resolvedLinkedEntry = await _resolveAliasEntry(
        repository: repository,
        bundle: bundle,
        entry: linkedEntry,
      );
      if (!context.mounted || resolvedLinkedEntry.id == resolvedEntry.id) {
        return;
      }

      await showWordDetail(
        context: context,
        entry: resolvedLinkedEntry,
        repository: repository,
        bundle: bundle,
        audioLibrary: audioLibrary,
        bookmarkStore: bookmarkStore,
        onActionResult: onActionResult,
      );
    }

    final openableWords = await _resolveOpenableWords(
      repository: repository,
      bundle: bundle,
      entry: localizedEntry,
      locale: resolvedLocale,
      translationService: translationService,
      currentEntryId: resolvedEntry.id,
    );
    if (!context.mounted) {
      return;
    }

    bool canOpenWord(String word) => openableWords.contains(word);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WordDetailScreen(
          entry: localizedEntry,
          audioLibrary: audioLibrary,
          bookmarkStore: bookmarkStore,
          onPlayClip: onPlayClip,
          onWordTapped: onWordTapped,
          canOpenWord: canOpenWord,
        ),
      ),
    );
  }

  static Future<DictionaryEntry> _resolveAliasEntry({
    required DictionaryRepository repository,
    required DictionaryBundle bundle,
    required DictionaryEntry entry,
  }) async {
    var current = entry;
    final visitedIds = <int>{};

    while (current.aliasTargetEntryId != null) {
      final targetId = current.aliasTargetEntryId!;
      if (!visitedIds.add(current.id)) {
        return current;
      }

      final target = await repository.entryByIdAsync(bundle, targetId);
      if (target == null) {
        return current;
      }
      current = target;
    }

    return current;
  }

  static Future<Set<String>> _resolveOpenableWords({
    required DictionaryRepository repository,
    required DictionaryBundle bundle,
    required DictionaryEntry entry,
    required Locale locale,
    required ChineseTranslationService translationService,
    required int currentEntryId,
  }) async {
    final uniqueWords = <String>{
      ...entry.wordSynonyms,
      ...entry.wordAntonyms,
      for (final sense in entry.senses) ...sense.definitionSynonyms,
      for (final sense in entry.senses) ...sense.definitionAntonyms,
    };

    final results = await Future.wait(
      uniqueWords.map((word) async {
        final normalizedLookupWord = await translationService
            .normalizeSearchInput(word, locale: locale);
        final linkedEntry = await repository.findLinkedEntryAsync(
          bundle,
          normalizedLookupWord,
        );
        if (linkedEntry == null) {
          return MapEntry(word, false);
        }

        final resolvedLinkedEntry = await _resolveAliasEntry(
          repository: repository,
          bundle: bundle,
          entry: linkedEntry,
        );
        return MapEntry(word, resolvedLinkedEntry.id != currentEntryId);
      }),
    );

    return {
      for (final result in results)
        if (result.value) result.key,
    };
  }
}
