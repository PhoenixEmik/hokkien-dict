import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

class EntryListItem extends StatelessWidget {
  const EntryListItem({
    super.key,
    required this.entry,
    required this.onTap,
    this.selected = false,
  });

  final DictionaryEntry entry;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = entry.briefSummary;

    final content = Card(
      clipBehavior: Clip.antiAlias,
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: AdaptiveListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          entry.hanji.isEmpty ? l10n.unlabeledHanji : entry.hanji,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.romanization.isNotEmpty)
              Text(
                entry.romanization,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          PlatformInfo.isIOS
              ? Icons.arrow_forward_ios_rounded
              : Icons.chevron_right,
          color: selected ? colorScheme.primary : null,
          size: PlatformInfo.isIOS ? 18 : 24,
        ),
        onTap: onTap,
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: _semanticLabel(entry, l10n),
        hint: l10n.entryOpenDetailsHint,
        child: ExcludeSemantics(child: content),
      ),
    );
  }
}

String _semanticLabel(DictionaryEntry entry, AppLocalizations l10n) {
  final parts = <String>[
    entry.hanji.isEmpty ? l10n.unlabeledHanji : entry.hanji,
  ];
  if (entry.romanization.isNotEmpty) {
    parts.add(l10n.romanizationLabel(entry.romanization));
  }
  if (entry.briefSummary.isNotEmpty) {
    parts.add(l10n.definitionLabel(entry.briefSummary));
  }
  return l10n.semanticsJoined(parts);
}
