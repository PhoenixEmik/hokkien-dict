import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';

class ReferenceArticleScreen extends StatelessWidget {
  const ReferenceArticleScreen({
    super.key,
    required this.title,
    required this.introduction,
    required this.sections,
    required this.sourceUrl,
  });

  final String title;
  final String introduction;
  final List<ReferenceArticleSection> sections;
  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  children: [
                    Text(
                      introduction,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
                    ),
                    const SizedBox(height: 24),
                    ...sections.map((section) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...section.paragraphs.map((paragraph) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  paragraph,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.65,
                                  ),
                                ),
                              );
                            }),
                            if (section.bullets.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...section.bullets.map((bullet) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          right: 10,
                                        ),
                                        child: Icon(
                                          Icons.circle,
                                          size: 7,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          bullet,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(height: 1.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            if (section.tables.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...section.tables.map((table) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ReferenceArticleTable(table: table),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 32),
                    Text(
                      l10n.referenceSource,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sourceUrl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ReferenceArticleSection {
  const ReferenceArticleSection({
    required this.title,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
    this.tables = const <ReferenceArticleTableData>[],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<ReferenceArticleTableData> tables;
}

class ReferenceArticleTableData {
  const ReferenceArticleTableData({
    required this.headers,
    required this.rows,
    this.caption,
  });

  final String? caption;
  final List<String> headers;
  final List<List<String>> rows;
}

class ReferenceArticleTable extends StatelessWidget {
  const ReferenceArticleTable({super.key, required this.table});

  final ReferenceArticleTableData table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outlineVariant;
    final surfaceColor = theme.colorScheme.surface;
    final mutedRowColor = theme.colorScheme.surfaceContainerLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (table.caption != null) ...[
          Text(
            table.caption!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: outlineColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.symmetric(
                  inside: BorderSide(color: outlineColor),
                  outside: BorderSide.none,
                ),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: mutedRowColor),
                    children: table.headers
                        .map((header) {
                          return _TableCell(
                            text: header,
                            textStyle: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  ...table.rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rowIndex.isOdd ? mutedRowColor : surfaceColor,
                      ),
                      children: row
                          .asMap()
                          .entries
                          .map((cell) {
                            final isFirstColumn = cell.key == 0;
                            return _TableCell(
                              text: cell.value,
                              textStyle:
                                  (isFirstColumn
                                          ? theme.textTheme.titleSmall
                                          : theme.textTheme.bodyLarge)
                                      ?.copyWith(
                                        fontWeight: isFirstColumn
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                            );
                          })
                          .toList(growable: false),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.text, required this.textStyle});

  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, style: textStyle),
    );
  }
}
