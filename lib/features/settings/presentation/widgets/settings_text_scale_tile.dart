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
    final sliderStep = _valueToSliderStep(sliderValue);
    final trailing = Text(
      '${(sliderValue * 100).toInt()}%',
      style: theme.textTheme.labelLarge?.copyWith(
        color: applePlatform ? resolveLiquidGlassForeground(context) : null,
        fontWeight: FontWeight.w700,
      ),
    );
    final subtitle = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (applePlatform)
            glass.GlassSlider(
              // GlassSlider 0.7.8 snaps incorrectly when min is non-zero.
              // Keep the package widget on a zero-based discrete scale and
              // map it back to 0.9..1.4 in the callback.
              value: sliderStep,
              min: 0,
              max: AppPreferences.readingTextScaleDivisions.toDouble(),
              divisions: AppPreferences.readingTextScaleDivisions,
              label: l10n.readingTextScaleLabel(sliderValue),
              activeColor: resolveLiquidGlassTint(context),
              inactiveColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              trackHeight: 4,
              thumbRadius: 13,
              quality: glass.GlassQuality.standard,
              onChanged: _handleDiscreteStepChanged,
            )
          else
            Slider.adaptive(
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

  double _valueToSliderStep(double currentValue) {
    final step =
        (AppPreferences.maxReadingTextScale -
            AppPreferences.minReadingTextScale) /
        AppPreferences.readingTextScaleDivisions;
    final index = ((currentValue - AppPreferences.minReadingTextScale) / step)
        .round();
    return index.clamp(0, AppPreferences.readingTextScaleDivisions).toDouble();
  }

  void _handleDiscreteStepChanged(double rawStep) {
    final index = rawStep.round().clamp(
      0,
      AppPreferences.readingTextScaleDivisions,
    );
    final step =
        (AppPreferences.maxReadingTextScale -
            AppPreferences.minReadingTextScale) /
        AppPreferences.readingTextScaleDivisions;
    onChanged(
      double.parse(
        (AppPreferences.minReadingTextScale + (index * step)).toStringAsFixed(
          2,
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
