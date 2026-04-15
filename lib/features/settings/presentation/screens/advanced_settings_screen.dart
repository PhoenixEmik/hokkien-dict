import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';
import 'package:taigi_dict/features/settings/settings.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.dictionaryLibrary,
    required this.onDownloadArchive,
    required this.onDownloadDictionarySource,
    required this.onRebuildDictionaryDatabase,
  });

  final OfflineAudioLibrary audioLibrary;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;
  final Future<void> Function() onDownloadDictionarySource;
  final Future<void> Function() onRebuildDictionaryDatabase;

  Future<void> _redownloadDictionarySource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '${l10n.redownload} ${l10n.dictionarySourceArchive}',
      content: l10n.dictionarySourceSubtitle,
      cancelLabel: l10n.cancelAction,
      confirmLabel: l10n.confirmAction,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await dictionaryLibrary.invalidateSource();
    if (!context.mounted) {
      return;
    }
    await onDownloadDictionarySource();
  }

  Future<void> _redownloadAudioArchive(
    BuildContext context,
    AudioArchiveType type,
  ) async {
    final l10n = AppLocalizations.of(context);
    final archiveLabel = type == AudioArchiveType.word
        ? l10n.audioWordArchive
        : l10n.audioSentenceArchive;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '${l10n.redownload} $archiveLabel',
      content: l10n.downloadApproximateSize(formatBytes(type.archiveBytes)),
      cancelLabel: l10n.cancelAction,
      confirmLabel: l10n.confirmAction,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await audioLibrary.invalidateArchive(type);
    if (!context.mounted) {
      return;
    }
    await onDownloadArchive(type);
  }

  Future<void> _confirmAndRebuild(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context: context,
      title: l10n.confirmRebuildDictionaryTitle,
      content: l10n.confirmRebuildDictionaryBody,
      cancelLabel: l10n.cancelAction,
      confirmLabel: l10n.confirmAction,
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await _handleRebuildDictionaryDatabase(context);
  }

  Future<void> _handleRebuildDictionaryDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    var closed = false;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.rebuildingDictionaryDatabase,
                      style: Theme.of(dialogContext).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Future<void>.delayed(Duration.zero);

    void closeProgressDialog() {
      if (closed) {
        return;
      }
      closed = true;
      unawaited(navigator.maybePop());
    }

    Object? error;
    try {
      await onRebuildDictionaryDatabase();
    } catch (caught) {
      error = caught;
    }

    if (!context.mounted) {
      return;
    }

    closeProgressDialog();

    showAppNotification(
      context,
      message: error == null
          ? l10n.rebuildDictionaryDatabaseSuccess
          : error is MissingDictionarySourceException
          ? l10n.downloadDictionarySourceFirst
          : error is CorruptedDictionarySourceException
          ? l10n.dictionarySourceCorrupted
          : error is MissingDictionarySheetException
          ? l10n.dictionarySourceSheetMissing(error.sheetName)
          : l10n.dictionaryDatabaseRebuildFailed('$error'),
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: l10n.advancedSettings,
        useNativeToolbar: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          children: [
            AdaptiveFormSection.insetGrouped(
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    '${l10n.redownload} ${l10n.dictionarySourceArchive}',
                  ),
                  subtitle: Text(l10n.dictionarySourceSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    unawaited(_redownloadDictionarySource(context));
                  },
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: Text('${l10n.redownload} ${l10n.audioWordArchive}'),
                  subtitle: Text(
                    l10n.downloadApproximateSize(
                      formatBytes(AudioArchiveType.word.archiveBytes),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    unawaited(
                      _redownloadAudioArchive(context, AudioArchiveType.word),
                    );
                  },
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(
                    '${l10n.redownload} ${l10n.audioSentenceArchive}',
                  ),
                  subtitle: Text(
                    l10n.downloadApproximateSize(
                      formatBytes(AudioArchiveType.sentence.archiveBytes),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    unawaited(
                      _redownloadAudioArchive(
                        context,
                        AudioArchiveType.sentence,
                      ),
                    );
                  },
                ),
                AdaptiveListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(l10n.rebuildDictionaryDatabase),
                  subtitle: Text(l10n.rebuildDictionaryDatabaseSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    unawaited(_confirmAndRebuild(context));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
