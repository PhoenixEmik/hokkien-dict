import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';

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
      leading: const Icon(Icons.language, color: Color(0xFF17454C)),
      title: Text(l10n.languageSetting),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (selection) {
            if (selection != null) {
              onSelected(selection);
            }
          },
          items: AppLocalizations.supportedLocales
              .map((locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(l10n.localeLabel(locale)),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}
