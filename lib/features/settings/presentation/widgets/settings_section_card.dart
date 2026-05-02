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
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) SettingsSectionHeader(title: title!),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: children,
              ).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}