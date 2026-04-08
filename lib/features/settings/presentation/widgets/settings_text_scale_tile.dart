import 'package:flutter/material.dart';

import '../../../../core/preferences/app_preferences.dart';

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

    return ListTile(
      title: const Text('字級'),
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
              label: _readingTextScaleLabel(value),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('小', style: theme.textTheme.bodySmall),
                Text('特大', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _readingTextScaleLabel(double value) {
  if (value <= 0.95) {
    return '較小';
  }
  if (value >= 1.35) {
    return '特大';
  }
  if (value >= 1.15) {
    return '較大';
  }
  return '標準';
}
