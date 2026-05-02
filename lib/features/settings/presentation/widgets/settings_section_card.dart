import 'package:flutter/material.dart';

import 'settings_section_header.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) SettingsSectionHeader(title: title!),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTileTheme(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              minLeadingWidth: 24,
              minVerticalPadding: 8,
              iconColor: colorScheme.onSurfaceVariant,
              textColor: colorScheme.onSurface,
              child: Column(
                children: ListTile.divideTiles(
                  context: context,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  tiles: children,
                ).toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
