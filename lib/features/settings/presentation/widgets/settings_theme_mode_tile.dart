import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';

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
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    const availablePreferences = [
      AppThemePreference.system,
      AppThemePreference.light,
      AppThemePreference.dark,
      AppThemePreference.amoled,
    ];

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(l10n.theme),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: DropdownMenu<AppThemePreference>(
          initialSelection: value,
          requestFocusOnTap: false,
          width: 220,
          textStyle: valueStyle,
          menuHeight: 280,
          onSelected: (preference) {
            if (preference != null) {
              onSelected(preference);
            }
          },
          dropdownMenuEntries: availablePreferences
              .map(
                (preference) => DropdownMenuEntry<AppThemePreference>(
                  value: preference,
                  label: _themeLabel(preference, l10n),
                ),
              )
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
