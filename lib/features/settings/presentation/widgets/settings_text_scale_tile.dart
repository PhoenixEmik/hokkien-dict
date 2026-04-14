import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/preferences/app_preferences.dart';

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
    final sliderValue = value
        .clamp(
          AppPreferences.minReadingTextScale,
          AppPreferences.maxReadingTextScale,
        )
        .toDouble();

    return ListTile(
      leading: const Icon(Icons.format_size),
      title: Text(l10n.fontSize),
      trailing: SizedBox(
        width: 50,
        child: Text(
          '${(sliderValue * 100).toInt()}%',
          textAlign: TextAlign.right,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: sliderValue,
              min: AppPreferences.minReadingTextScale,
              max: AppPreferences.maxReadingTextScale,
              divisions: AppPreferences.readingTextScaleDivisions,
              label: l10n.readingTextScaleLabel(sliderValue),
              onChanged: _handleDiscreteValueChanged,
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

  void _handleDiscreteValueChanged(double rawValue) {
    final step =
        (AppPreferences.maxReadingTextScale -
            AppPreferences.minReadingTextScale) /
        AppPreferences.readingTextScaleDivisions;
    final snapped =
        AppPreferences.minReadingTextScale +
        (((rawValue - AppPreferences.minReadingTextScale) / step).round() *
            step);
    onChanged(double.parse(snapped.toStringAsFixed(2)));
  }
}
