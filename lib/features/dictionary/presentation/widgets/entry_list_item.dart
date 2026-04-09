import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';

class EntryListItem extends StatelessWidget {
  const EntryListItem({super.key, required this.entry, required this.onTap});

  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final applePlatform = isApplePlatform(context);

    Widget content;
    if (applePlatform) {
      content = LiquidGlassSection(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.hanji.isEmpty
                              ? l10n.unlabeledHanji
                              : entry.hanji,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: resolveLiquidGlassForeground(context),
                          ),
                        ),
                        if (entry.romanization.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.romanization,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: resolveLiquidGlassTint(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (entry.briefSummary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            entry.briefSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: resolveLiquidGlassSecondaryForeground(
                                context,
                              ),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    color: resolveLiquidGlassSecondaryForeground(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          titleAlignment: ListTileTitleAlignment.top,
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
              if (entry.briefSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.briefSummary,
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
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

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
