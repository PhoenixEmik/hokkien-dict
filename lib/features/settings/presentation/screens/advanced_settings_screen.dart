import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/utils/dialog_utils.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_section_header.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.onRebuildDictionaryDatabase,
  });

  final Future<void> Function() onRebuildDictionaryDatabase;

  Future<void> _confirmAndRebuild(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdaptiveConfirmationDialog(
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? l10n.rebuildDictionaryDatabaseSuccess
                : error is MissingDictionarySourceException
                ? l10n.downloadDictionarySourceFirst
                : error is CorruptedDictionarySourceException
                ? l10n.dictionarySourceCorrupted
                : error is MissingDictionarySheetException
                ? l10n.dictionarySourceSheetMissing(error.sheetName)
                : l10n.dictionaryDatabaseRebuildFailed('$error'),
          ),
          backgroundColor: error == null
              ? const Color(0xFF0E2F35)
              : const Color(0xFF8A3B1F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final applePlatform = isApplePlatform(context);
    final sectionChildren = [
      ListTile(
        leading: Icon(Icons.storage_outlined, color: colorScheme.primary),
        title: Text(l10n.rebuildDictionaryDatabase),
        subtitle: Text(l10n.rebuildDictionaryDatabaseSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          unawaited(_confirmAndRebuild(context));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettings)),
      body: LiquidGlassBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListTileTheme(
              contentPadding: EdgeInsets.symmetric(
                horizontal: applePlatform ? 20 : 24,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  applePlatform ? 16 : 8,
                  16,
                  28,
                ),
                children: [
                  SettingsSectionHeader(title: l10n.advancedSettings),
                  applePlatform
                      ? LiquidGlassSection(children: sectionChildren)
                      : Column(children: sectionChildren),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
