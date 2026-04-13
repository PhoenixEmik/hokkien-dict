import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

class SettingsGlassOptionMenu<T> extends StatefulWidget {
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
  State<SettingsGlassOptionMenu<T>> createState() =>
      _SettingsGlassOptionMenuState<T>();
}

class _SettingsGlassOptionMenuState<T>
    extends State<SettingsGlassOptionMenu<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _menuEntry;

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleMenu,
        child: _SettingsGlassMenuTrigger(label: widget.label),
      ),
    );
  }

  void _toggleMenu() {
    if (_menuEntry == null) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    final menuContext = context;

    _menuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: _SettingsGlassMenuPanel<T>(
                value: widget.value,
                items: widget.items,
                itemLabel: widget.itemLabel,
                settings: _settingsMenuGlassSettings(menuContext),
                onSelected: (item) {
                  _hideMenu();
                  if (item != widget.value) {
                    widget.onSelected(item);
                  }
                },
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_menuEntry!);
  }

  void _hideMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }
}

class _SettingsGlassMenuPanel<T> extends StatelessWidget {
  const _SettingsGlassMenuPanel({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.settings,
    required this.onSelected,
  });

  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final glass.LiquidGlassSettings settings;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final selectedColor = CupertinoColors.activeBlue.resolveFrom(context);

    return Material(
      color: Colors.transparent,
      child: glass.GlassPanel(
        width: 216,
        padding: const EdgeInsets.symmetric(vertical: 6),
        shape: const glass.LiquidRoundedSuperellipse(borderRadius: 22),
        settings: settings,
        useOwnLayer: true,
        quality: glass.GlassQuality.premium,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              _SettingsGlassMenuItem(
                label: itemLabel(item),
                selected: item == value,
                textColor: textColor,
                selectedColor: selectedColor,
                onTap: () => onSelected(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGlassMenuItem extends StatelessWidget {
  const _SettingsGlassMenuItem({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color textColor;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 12),
                Icon(CupertinoIcons.checkmark, color: selectedColor, size: 18),
              ],
            ],
          ),
        ),
      ),
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
        : Colors.white.withValues(alpha: 0.82),
    lightIntensity: 0.72,
    ambientStrength: isDark ? 0.22 : 0.3,
    refractiveIndex: 1.18,
    saturation: isDark ? 1.25 : 1.08,
    chromaticAberration: 0.02,
  );
}
