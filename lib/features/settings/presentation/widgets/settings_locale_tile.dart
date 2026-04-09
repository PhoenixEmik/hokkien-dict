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
      title: Text(l10n.languageSetting),
      subtitle: Text(l10n.localeLabel(value)),
      trailing: PopupMenuButton<Locale>(
        tooltip: l10n.languageSetting,
        initialValue: value,
        onSelected: onSelected,
        itemBuilder: (context) {
          return AppLocalizations.supportedLocales
              .map((locale) {
                return PopupMenuItem<Locale>(
                  value: locale,
                  child: Text(l10n.localeLabel(locale)),
                );
              })
              .toList(growable: false);
        },
      ),
    );
  }
}
