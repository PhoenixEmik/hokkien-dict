import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';

class BookmarkEmptyState extends StatelessWidget {
  const BookmarkEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final applePlatform = isApplePlatform(context);

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            applePlatform ? Icons.bookmark_outline : Icons.bookmark_border,
            size: 44,
            color: applePlatform
                ? resolveLiquidGlassTint(context)
                : theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.bookmarksEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: applePlatform
                  ? resolveLiquidGlassForeground(context)
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookmarksEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: applePlatform
                  ? resolveLiquidGlassSecondaryForeground(context)
                  : theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Center(
      child: applePlatform ? LiquidGlassSection(children: [content]) : content,
    );
  }
}
