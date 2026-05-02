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
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languageSetting),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.localeLabel(value), style: valueStyle),
          PopupMenuButton<Locale>(
            initialValue: value,
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: onSelected,
            itemBuilder: (context) {
              return AppLocalizations.supportedLocales
                  .map(
                    (locale) => PopupMenuItem<Locale>(
                      value: locale,
                      child: Text(l10n.localeLabel(locale)),
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
