import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';

class BookmarkEmptyState extends StatelessWidget {
  const BookmarkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.bookmarksEmptyTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bookmarksEmptyBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
