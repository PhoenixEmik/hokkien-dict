import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';

class SettingsTextScaleTile extends StatelessWidget {
  const SettingsTextScaleTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListTile(
      title: Text(l10n.fontSize),
      trailing: Text(
        '${(value * 100).round()}%',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: value,
              min: AppPreferences.minReadingTextScale,
              max: AppPreferences.maxReadingTextScale,
              divisions: 5,
              label: l10n.readingTextScaleLabel(value),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.small, style: theme.textTheme.bodySmall),
                Text(l10n.extraLarge, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
