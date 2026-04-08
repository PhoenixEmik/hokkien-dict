import 'package:flutter/material.dart';

class SearchWorkspaceCard extends StatelessWidget {
  const SearchWorkspaceCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: '輸入台語漢字、白話字或華語詞義',
      leading: const Icon(Icons.search),
      trailing: controller.text.isEmpty
          ? null
          : [
              IconButton(
                onPressed: () {
                  controller.clear();
                },
                icon: const Icon(Icons.close),
              ),
            ],
      onSubmitted: onSubmitted,
    );
  }
}

class SearchHistorySection extends StatelessWidget {
  const SearchHistorySection({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearHistory,
  });

  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final Future<void> Function() onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '搜尋紀錄',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF18363C),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '清除搜尋紀錄',
                  onPressed: onClearHistory,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map((query) {
                    return ActionChip(
                      label: Text(query),
                      avatar: const Icon(Icons.history, size: 18),
                      onPressed: () => onHistoryTap(query),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = query.trim().isEmpty ? '開始搜尋' : '找不到符合的結果';
    final body = query.trim().isEmpty
        ? '輸入台語漢字、白話字，或華語釋義後才顯示詞條。'
        : '換個寫法試試看，或改用另一個查詢方向。';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoResultsState extends StatelessWidget {
  const NoResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '找不到符合的詞條',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5A6D71),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SearchLoadingState extends StatelessWidget {
  const SearchLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
