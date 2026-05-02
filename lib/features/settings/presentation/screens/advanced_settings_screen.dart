import 'dart:async';
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

  String _dictionarySourceApproximateSize(AppLocalizations l10n) {
    final snapshot = dictionaryLibrary.downloadSnapshot;
    final bytes = snapshot.totalBytes > 0
        ? snapshot.totalBytes
        : snapshot.downloadedBytes;
    if (bytes <= 0) {
      return l10n.unknownSize;
    }
    return formatBytes(bytes);
  }

  Future<void> _redownloadDictionarySource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context: context,
      title: l10n.redownloadConfirmationTitle(l10n.dictionarySourceArchive),
      content: l10n.redownloadConfirmationBody(
        _dictionarySourceApproximateSize(l10n),
      ),
      cancelLabel: l10n.cancelAction,
      confirmLabel: l10n.redownload,
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
      title: l10n.redownloadConfirmationTitle(archiveLabel),
      content: l10n.redownloadConfirmationBody(
        formatBytes(type.archiveBytes),
      ),
      cancelLabel: l10n.cancelAction,
      confirmLabel: l10n.redownload,
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
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.rebuildingDictionaryDatabase,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
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
    } finally {
      closeProgressDialog();
    }

    if (!context.mounted) {
      return;
    }

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          SettingsSectionCard(
            title: l10n.offlineResourceMaintenance,
            children: [
              ListTile(
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
              ListTile(
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
              ListTile(
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
            ],
          ),
          SettingsSectionCard(
            title: l10n.rebuildDictionaryDatabase,
            children: [
              ListTile(
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
    );
  }
}
