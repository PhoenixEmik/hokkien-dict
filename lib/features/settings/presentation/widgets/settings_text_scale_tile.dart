import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/preferences/app_preferences.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

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
    final applePlatform = isApplePlatform(context);

    return ListTile(
      leading: Icon(Icons.format_size, color: theme.colorScheme.primary),
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
            if (applePlatform)
              CupertinoTheme(
                data: CupertinoTheme.of(
                  context,
                ).copyWith(primaryColor: resolveLiquidGlassTint(context)),
                child: CupertinoSlider(
                  value: value,
                  min: AppPreferences.minReadingTextScale,
                  max: AppPreferences.maxReadingTextScale,
                  divisions: 5,
                  onChanged: onChanged,
                ),
              )
            else
              Slider.adaptive(
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
