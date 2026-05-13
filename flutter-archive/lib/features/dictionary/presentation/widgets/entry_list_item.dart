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
    final backgroundColor = selected
        ? colorScheme.secondaryContainer.withValues(alpha: 0.9)
        : colorScheme.surfaceContainerLow;
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.52)
        : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final trailingColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final content = Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: borderColor,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: ListTile(
        tileColor: backgroundColor,
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: trailingColor,
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
