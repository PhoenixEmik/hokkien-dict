import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';
import 'package:taigi_dict/features/settings/settings.dart';


class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.onRebuildDictionaryDatabase,
  });

  final Future<void> Function() onRebuildDictionaryDatabase;

  Future<void> _confirmAndRebuild(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.confirmRebuildDictionaryTitle),
          content: Text(l10n.confirmRebuildDictionaryBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await _handleRebuildDictionaryDatabase(context);
  }

  Future<void> _handleRebuildDictionaryDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                const SizedBox(width: 16),
                Expanded(child: Text(l10n.rebuildingDictionaryDatabase)),
              ],
            ),
          ),
        );
      },
    );

    Object? error;
    try {
      await onRebuildDictionaryDatabase();
    } catch (caught) {
      error = caught;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            clipBehavior: Clip.hardEdge,
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(l10n.rebuildDictionaryDatabase),
              subtitle: Text(l10n.rebuildDictionaryDatabaseSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                unawaited(_confirmAndRebuild(context));
              },
            ),
          ),
        ],
      ),
    );
  }
}


