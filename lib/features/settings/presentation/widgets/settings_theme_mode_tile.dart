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
      title: Text(l10n.theme),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_themeLabel(value, l10n)),
          const SizedBox(height: 8),
          DropdownMenu<AppThemePreference>(
            key: ValueKey<AppThemePreference>(value),
            initialSelection: value,
            requestFocusOnTap: false,
            expandedInsets: EdgeInsets.zero,
            label: Text(l10n.displayMode),
            onSelected: (selection) {
              if (selection != null) {
                onSelected(selection);
              }
            },
            dropdownMenuEntries: AppThemePreference.values
                .map((mode) {
                  return DropdownMenuEntry<AppThemePreference>(
                    value: mode,
                    label: _themeLabel(mode, l10n),
                  );
                })
                .toList(growable: false),
          ),
        ],
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
