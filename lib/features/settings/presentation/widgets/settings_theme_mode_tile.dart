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
    final isApplePlatform =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final availablePreferences = isApplePlatform
        ? const [
            AppThemePreference.system,
            AppThemePreference.light,
            AppThemePreference.dark,
          ]
        : const [
            AppThemePreference.system,
            AppThemePreference.light,
            AppThemePreference.dark,
            AppThemePreference.amoled,
          ];

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(l10n.theme),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _themeLabel(value, l10n, isApplePlatform: isApplePlatform),
            style: valueStyle,
          ),
          PopupMenuButton<AppThemePreference>(
            initialValue: value,
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: onSelected,
            itemBuilder: (context) {
              return availablePreferences
                  .map(
                    (preference) => PopupMenuItem<AppThemePreference>(
                      value: preference,
                      child: Text(
                        _themeLabel(
                          preference,
                          l10n,
                          isApplePlatform: isApplePlatform,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false);
            },
          ),
        ],
      ),
    );
  }
}

String _themeLabel(
  AppThemePreference value,
  AppLocalizations l10n, {
  required bool isApplePlatform,
}) {
  final effectiveValue =
      isApplePlatform && value == AppThemePreference.amoled
      ? AppThemePreference.dark
      : value;

  return l10n.themeLabel(switch (effectiveValue) {
    AppThemePreference.system => AppThemePreferenceProxy.system,
    AppThemePreference.light => AppThemePreferenceProxy.light,
    AppThemePreference.dark => AppThemePreferenceProxy.dark,
    AppThemePreference.amoled => AppThemePreferenceProxy.amoled,
  });
}
