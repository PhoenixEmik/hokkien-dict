import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';

class SettingsThemeModeTile extends StatelessWidget {
  const SettingsThemeModeTile({
    super.key,
    required this.value,
    required this.onSelected,
  });

  final AppThemePreference value;
  final ValueChanged<AppThemePreference> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final applePlatform = isApplePlatform(context);

    return ListTile(
      leading: Icon(Icons.palette, color: colorScheme.primary),
      title: Text(l10n.theme),
      trailing: applePlatform
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () async {
                final selected =
                    await showCupertinoModalPopup<AppThemePreference>(
                      context: context,
                      builder: (context) {
                        return CupertinoActionSheet(
                          actions: AppThemePreference.values
                              .map((mode) {
                                return CupertinoActionSheetAction(
                                  isDefaultAction: mode == value,
                                  onPressed: () {
                                    Navigator.of(context).pop(mode);
                                  },
                                  child: Text(_themeLabel(mode, l10n)),
                                );
                              })
                              .toList(growable: false),
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(l10n.cancelAction),
                          ),
                        );
                      },
                    );
                if (selected != null) {
                  onSelected(selected);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _themeLabel(value, l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: resolveLiquidGlassForeground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: resolveLiquidGlassSecondaryForeground(context),
                  ),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<AppThemePreference>(
                value: value,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: (selection) {
                  if (selection != null) {
                    onSelected(selection);
                  }
                },
                items: AppThemePreference.values
                    .map((mode) {
                      return DropdownMenuItem<AppThemePreference>(
                        value: mode,
                        child: Text(_themeLabel(mode, l10n)),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
    );
  }
}

String _themeLabel(AppThemePreference value, AppLocalizations l10n) {
  return l10n.themeLabel(switch (value) {
    AppThemePreference.system => AppThemePreferenceProxy.system,
    AppThemePreference.light => AppThemePreferenceProxy.light,
    AppThemePreference.dark => AppThemePreferenceProxy.dark,
    AppThemePreference.amoled => AppThemePreferenceProxy.amoled,
  });
}
