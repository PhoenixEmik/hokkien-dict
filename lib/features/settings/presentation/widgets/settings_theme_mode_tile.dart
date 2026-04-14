import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/preferences/app_preferences.dart';

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
    final darkEnabled =
        value == AppThemePreference.dark || value == AppThemePreference.amoled;

    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode_outlined),
      title: Text(l10n.theme),
      subtitle: Text(
        darkEnabled
            ? _themeLabel(AppThemePreference.dark, l10n)
            : _themeLabel(AppThemePreference.light, l10n),
      ),
      value: darkEnabled,
      onChanged: (enabled) {
        onSelected(
          enabled ? AppThemePreference.dark : AppThemePreference.light,
        );
      },
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
