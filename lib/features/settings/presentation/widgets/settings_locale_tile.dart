import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';

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
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.languageSetting),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: value,
          onChanged: (selection) {
            if (selection != null) onSelected(selection);
          },
          items: AppLocalizations.supportedLocales
              .map(
                (locale) => DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(l10n.localeLabel(locale)),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
