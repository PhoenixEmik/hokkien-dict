import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

class SettingsGlassOptionMenu<T> extends StatelessWidget {
  const SettingsGlassOptionMenu({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  final T value;
  final String label;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return glass.GlassMenu(
      menuWidth: 216,
      menuBorderRadius: 22,
      glassSettings: _settingsMenuGlassSettings(context),
      quality: glass.GlassQuality.premium,
      trigger: _SettingsGlassMenuTrigger(label: label),
      items: [
        for (final item in items)
          glass.GlassMenuItem(
            title: itemLabel(item),
            height: 48,
            trailing: item == value
                ? Icon(
                    CupertinoIcons.checkmark,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                    size: 18,
                  )
                : null,
            onTap: () {
              if (item != value) {
                onSelected(item);
              }
            },
          ),
      ],
    );
  }
}

class _SettingsGlassMenuTrigger extends StatelessWidget {
  const _SettingsGlassMenuTrigger({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
    );
  }
}

glass.LiquidGlassSettings _settingsMenuGlassSettings(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return glass.LiquidGlassSettings(
    blur: 24,
    thickness: 22,
    glassColor: isDark
        ? Colors.black.withValues(alpha: 0.46)
        : Colors.black.withValues(alpha: 0.72),
    lightIntensity: 0.72,
    ambientStrength: isDark ? 0.22 : 0.16,
    refractiveIndex: 1.18,
    saturation: isDark ? 1.25 : 0.95,
    chromaticAberration: 0.02,
  );
}
