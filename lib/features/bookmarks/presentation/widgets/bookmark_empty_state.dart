import 'package:flutter/material.dart';

class BookmarkEmptyState extends StatelessWidget {
  const BookmarkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 44,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              '尚未加入任何書籤',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF18363C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '從詞條詳細頁點選書籤圖示，就會顯示在這裡。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5A6D71),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
