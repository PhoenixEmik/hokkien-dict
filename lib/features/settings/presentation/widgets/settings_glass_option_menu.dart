import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

/// A settings-row trailing menu that replaces the former GlassMenu.
///
/// Uses [AdaptivePopupMenuButton.widget] so that:
///   • iOS 26+ → native UIMenu via platform channel
///   • iOS <26 → CupertinoActionSheet
///   • Android/desktop → Material PopupMenuButton
///
/// The custom trigger widget (label + chevron) is passed as the [child],
/// preserving the same visual appearance as the old GlassMenu trigger.
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
    final menuItems = <AdaptivePopupMenuEntry>[
      for (final item in items)
        AdaptivePopupMenuItem<T>(
          label: itemLabel(item),
          // Show a check-mark icon on the currently selected item.
          // On iOS 26+ this is rendered as an SF Symbol;
          // on older platforms the icon field is ignored for the checkmark —
          // the label alone is sufficient to communicate selection.
          icon: item == value ? CupertinoIcons.checkmark : null,
          value: item,
        ),
    ];

    return AdaptivePopupMenuButton.widget<T>(
      items: menuItems,
      onSelected: (_, entry) {
        if (entry.value != null && entry.value != value) {
          onSelected(entry.value as T);
        }
      },
      tint: resolveLiquidGlassTint(context),
      child: _SettingsMenuTrigger(label: label),
    );
  }
}

// ---------------------------------------------------------------------------
// Private trigger chip — identical look to the old GlassMenu trigger.
// ---------------------------------------------------------------------------
class _SettingsMenuTrigger extends StatelessWidget {
  const _SettingsMenuTrigger({required this.label});

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
