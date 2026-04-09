import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final applePlatform = isApplePlatform(context);

    return ListTile(
      leading: Icon(Icons.language, color: colorScheme.primary),
      title: Text(l10n.languageSetting),
      trailing: applePlatform
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () async {
                final selected = await showCupertinoModalPopup<Locale>(
                  context: context,
                  builder: (context) {
                    return CupertinoActionSheet(
                      actions: AppLocalizations.supportedLocales
                          .map((locale) {
                            return CupertinoActionSheetAction(
                              isDefaultAction: locale == value,
                              onPressed: () {
                                Navigator.of(context).pop(locale);
                              },
                              child: Text(l10n.localeLabel(locale)),
                            );
                          })
                          .toList(growable: false),
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.cancelAction),
                      ),
                    );
                  },
                );
                if (selected != null) {
                  onSelected(selected);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.localeLabel(value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: resolveLiquidGlassForeground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: resolveLiquidGlassSecondaryForeground(context),
                  ),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
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
