import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';

class SettingsLocaleTile extends StatelessWidget {
  const SettingsLocaleTile({
    super.key,
    required this.value,
    required this.onSelected,
  });

  final Locale value;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languageSetting),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: DropdownMenu<Locale>(
          initialSelection: value,
          requestFocusOnTap: false,
          width: 220,
          textStyle: valueStyle,
          menuHeight: 240,
          onSelected: (locale) {
            if (locale != null) {
              onSelected(locale);
            }
          },
          dropdownMenuEntries: AppLocalizations.supportedLocales
              .map(
                (locale) => DropdownMenuEntry<Locale>(
                  value: locale,
                  label: l10n.localeLabel(locale),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
