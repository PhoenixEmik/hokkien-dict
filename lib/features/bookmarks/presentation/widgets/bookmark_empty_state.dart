import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

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

    if (!applePlatform) {
      return Center(child: content);
    }

    final brightness = theme.brightness;
    final settings = glass.LiquidGlassSettings(
      blur: 28,
      thickness: 34,
      glassColor: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.12),
      lightIntensity: brightness == Brightness.dark ? 0.44 : 0.62,
      ambientStrength: brightness == Brightness.dark ? 0.08 : 0.03,
      refractiveIndex: 1.16,
      saturation: brightness == Brightness.dark ? 1.2 : 1.06,
      chromaticAberration: 0.008,
      specularSharpness: glass.GlassSpecularSharpness.medium,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: glass.GlassCard(
          useOwnLayer: true,
          quality: glass.GlassQuality.standard,
          settings: settings,
          shape: const glass.LiquidRoundedSuperellipse(borderRadius: 24),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }
}
