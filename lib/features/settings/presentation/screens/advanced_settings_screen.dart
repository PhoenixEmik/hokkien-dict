import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/utils/dialog_utils.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.onRebuildDictionaryDatabase,
  });

  final Future<void> Function() onRebuildDictionaryDatabase;

  glass.LiquidGlassSettings _sectionSettings(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return glass.LiquidGlassSettings(
      blur: 28,
      thickness: 34,
      glassColor: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.12),
      lightIntensity: brightness == Brightness.dark ? 0.44 : 0.62,
      ambientStrength: brightness == Brightness.dark ? 0.08 : 0.03,
      refractiveIndex: 1.16,
      saturation: brightness == Brightness.dark ? 1.2 : 1.06,
      chromaticAberration: 0.008,
      specularSharpness: glass.GlassSpecularSharpness.medium,
    );
  }

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

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListTileTheme(
          contentPadding: EdgeInsets.symmetric(
            horizontal: applePlatform ? 20 : 24,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, applePlatform ? 12 : 8, 16, 28),
            children: [
              SettingsSectionHeader(title: l10n.advancedSettings),
              applePlatform
                  ? _GlassSettingsGroup(
                      settings: _sectionSettings(context),
                      children: sectionChildren,
                    )
                  : Card(child: Column(children: sectionChildren)),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: applePlatform
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: applePlatform
          ? glass.GlassAppBar(
              useOwnLayer: true,
              quality: glass.GlassQuality.premium,
              backgroundColor: Theme.of(context).colorScheme.surface,
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  CupertinoIcons.back,
                  color: resolveLiquidGlassTint(context),
                  size: 22,
                ),
              ),
              title: Text(
                l10n.advancedSettings,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: resolveLiquidGlassForeground(context),
                ),
              ),
            )
          : AppBar(title: Text(l10n.advancedSettings)),
      body: applePlatform ? LiquidGlassBackground(child: body) : body,
    );
  }
}

class _GlassSettingsGroup extends StatelessWidget {
  const _GlassSettingsGroup({required this.settings, required this.children});

  final glass.LiquidGlassSettings settings;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return glass.GlassCard(
      useOwnLayer: true,
      quality: glass.GlassQuality.standard,
      settings: settings,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 4),
      shape: const glass.LiquidRoundedSuperellipse(borderRadius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 72,
                endIndent: 16,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }
}
