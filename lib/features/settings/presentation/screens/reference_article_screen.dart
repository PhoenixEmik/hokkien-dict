import 'package:flutter/material.dart';

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
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 32),
                    Text(
                      '資料來源',
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
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}
