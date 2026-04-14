import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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

    return AdaptiveListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(l10n.theme),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_themeLabel(value, l10n)),
          AdaptivePopupMenuButton.icon<AppThemePreference>(
            icon: PlatformInfo.isIOS
                ? 'chevron.up.chevron.down'
                : Icons.arrow_drop_down,
            items: const [
              AppThemePreference.system,
              AppThemePreference.light,
              AppThemePreference.dark,
              AppThemePreference.amoled,
            ]
                .map(
                  (preference) => AdaptivePopupMenuItem<AppThemePreference>(
                    label: _themeLabel(preference, l10n),
                    value: preference,
                  ),
                )
                .toList(growable: false),
            onSelected: (index, entry) {
              final selectedPreference = entry.value;
              if (selectedPreference != null) {
                onSelected(selectedPreference);
              }
            },
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
