import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
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
    final sliderValue = value
        .clamp(
          AppPreferences.minReadingTextScale,
          AppPreferences.maxReadingTextScale,
        )
        .toDouble();

    final trailing = SizedBox(
      width: 50,
      child: Text(
        '${(sliderValue * 100).toInt()}%',
        textAlign: TextAlign.right,
        style: theme.textTheme.labelLarge?.copyWith(
          color: applePlatform ? resolveLiquidGlassForeground(context) : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    // AdaptiveSlider accepts the true domain (min: 0.9, max: 1.4) directly.
    // The zero-based index workaround that GlassSlider 0.7.8 required is gone.
    final slider = AdaptiveSlider(
      value: sliderValue,
      min: AppPreferences.minReadingTextScale,
      max: AppPreferences.maxReadingTextScale,
      divisions: AppPreferences.readingTextScaleDivisions,
      label: l10n.readingTextScaleLabel(sliderValue),
      activeColor: applePlatform ? resolveLiquidGlassTint(context) : null,
      onChanged: _handleDiscreteValueChanged,
    );

    final subtitle = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          slider,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.small,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: applePlatform
                      ? resolveLiquidGlassSecondaryForeground(context)
                      : null,
                ),
              ),
              Text(
                l10n.extraLarge,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: applePlatform
                      ? resolveLiquidGlassSecondaryForeground(context)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (applePlatform) {
      return glass.GlassListTile(
        showDivider: false,
        leadingIconColor: resolveLiquidGlassTint(context),
        titleStyle: resolveGlassListTileTitleStyle(context),
        subtitleStyle: resolveGlassListTileSubtitleStyle(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: const Icon(Icons.format_size),
        title: Text(l10n.fontSize),
        trailing: trailing,
        subtitle: subtitle,
      );
    }

    return ListTile(
      leading: Icon(Icons.format_size, color: theme.colorScheme.primary),
      title: Text(l10n.fontSize),
      trailing: trailing,
      subtitle: subtitle,
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
