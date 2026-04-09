import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';

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

    return ListTile(
      leading: const Icon(Icons.palette, color: Color(0xFF17454C)),
      title: Text(l10n.theme),
      trailing: DropdownButtonHideUnderline(
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
