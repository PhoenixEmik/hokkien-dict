import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

class SearchWorkspaceCard extends StatelessWidget {
  const SearchWorkspaceCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final applePlatform = isApplePlatform(context);

    if (applePlatform) {
      return glass.GlassSearchBar(
        controller: controller,
        placeholder: l10n.searchHint,
        onSubmitted: onSubmitted,
        onChanged: (_) {},
        autofocus: autofocus,
        useOwnLayer: true,
        quality: glass.GlassQuality.standard,
        searchIconColor: resolveLiquidGlassSecondaryForeground(context),
        clearIconColor: resolveLiquidGlassSecondaryForeground(context),
        cancelButtonColor: resolveLiquidGlassTint(context),
        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: resolveLiquidGlassForeground(context),
          fontWeight: FontWeight.w600,
        ),
        placeholderStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: resolveLiquidGlassSecondaryForeground(context),
        ),
      );
    }

    return SearchBar(
      controller: controller,
      hintText: l10n.searchHint,
      autoFocus: autofocus,
      leading: const Icon(Icons.search),
      trailing: controller.text.isEmpty
          ? null
          : [
              IconButton(
                tooltip: l10n.clearSearch,
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

class AppleSearchFloatingButton extends StatelessWidget {
  const AppleSearchFloatingButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = resolveLiquidGlassTint(context);

    return Semantics(
      button: true,
      label: label,
      child: glass.GlassButton.custom(
        onTap: onTap,
        label: label,
        width: 156,
        height: 58,
        useOwnLayer: true,
        quality: glass.GlassQuality.premium,
        shape: const glass.LiquidRoundedSuperellipse(borderRadius: 28),
        glowColor: tint.withValues(alpha: 0.28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 18,
                color: resolveLiquidGlassForeground(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: resolveLiquidGlassForeground(context),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final applePlatform = isApplePlatform(context);
    final brightness = theme.brightness;

    if (applePlatform) {
      final chipBackgroundColor = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.06);
      final chipBorderColor = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.08);
      final chipTextColor = brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;
      final chipIconColor = brightness == Brightness.dark
          ? Colors.blueAccent.shade100
          : theme.colorScheme.primary;

      return LiquidGlassSection(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.searchHistory,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: resolveLiquidGlassForeground(context),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                        onPressed: onClearHistory,
                        child: Icon(
                          CupertinoIcons.delete_simple,
                          color: resolveLiquidGlassTint(context),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: history
                          .map((query) {
                            return Semantics(
                              button: true,
                              label: '${l10n.searchHistory} $query',
                              hint: l10n.searchHint,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                onPressed: () => onHistoryTap(query),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: chipBackgroundColor,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: chipBorderColor),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: chipBackgroundColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              CupertinoIcons.time,
                                              size: 14,
                                              color: chipIconColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          query,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: chipTextColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
                    l10n.searchHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.clearSearchHistory,
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
                    return Semantics(
                      button: true,
                      label: '${l10n.searchHistory} $query',
                      hint: l10n.searchHint,
                      child: ActionChip(
                        label: Text(query),
                        avatar: const Icon(Icons.history, size: 18),
                        onPressed: () => onHistoryTap(query),
                      ),
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
    final l10n = AppLocalizations.of(context);
    final title = query.trim().isEmpty ? l10n.startSearch : l10n.noResultsTitle;
    final body = query.trim().isEmpty
        ? l10n.startSearchBody
        : l10n.noResultsBody;
    final applePlatform = isApplePlatform(context);

    if (applePlatform) {
      return LiquidGlassSection(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: resolveLiquidGlassForeground(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: resolveLiquidGlassSecondaryForeground(context),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

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
                color: theme.colorScheme.onSurfaceVariant,
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
    if (isApplePlatform(context)) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noResultsShort,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: resolveLiquidGlassSecondaryForeground(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: Text(
        AppLocalizations.of(context).noResultsShort,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    if (isApplePlatform(context)) {
      final brightness = Theme.of(context).brightness;
      final baseFill = brightness == Brightness.light
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.06);
      final glowFill = brightness == Brightness.light
          ? Colors.white.withValues(alpha: 0.42)
          : Colors.white.withValues(alpha: 0.14);
      final strokeColor = brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.14);
      final lineColor = brightness == Brightness.light
          ? Colors.white.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.18);
      final mutedLineColor = brightness == Brightness.light
          ? Colors.white.withValues(alpha: 0.46)
          : Colors.white.withValues(alpha: 0.10);

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.20, end: 0.70),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, opacity, child) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(3, (index) {
                final cardFill = Color.lerp(
                  baseFill,
                  glowFill,
                  index.isEven ? opacity : opacity * 0.66,
                )!;
                final shimmerColor = Color.lerp(
                  lineColor,
                  Colors.white.withValues(
                    alpha: brightness == Brightness.light ? 0.92 : 0.28,
                  ),
                  opacity,
                )!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 118,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cardFill,
                              baseFill,
                              Color.lerp(cardFill, baseFill, 0.45)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: strokeColor, width: 0.5),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -8,
                              left: 12 + (index * 18),
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: shimmerColor.withValues(
                                          alpha: brightness == Brightness.light
                                              ? 0.26
                                              : 0.12,
                                        ),
                                        blurRadius: 22,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(width: 24, height: 24),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                16,
                                14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _SkeletonLine(
                                          widthFactor: 0.30 + (index * 0.06),
                                          height: 18,
                                          color: shimmerColor,
                                        ),
                                        const SizedBox(height: 8),
                                        _SkeletonLine(
                                          widthFactor: 0.22 + (index * 0.03),
                                          height: 12,
                                          color: lineColor,
                                        ),
                                        const SizedBox(height: 12),
                                        _SkeletonLine(
                                          widthFactor: 0.82,
                                          height: 10,
                                          color: mutedLineColor,
                                        ),
                                        const SizedBox(height: 6),
                                        _SkeletonLine(
                                          widthFactor: 0.64,
                                          height: 10,
                                          color: mutedLineColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _SkeletonCircle(
                                    size: 18,
                                    color: mutedLineColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  final double widthFactor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor.clamp(0.0, 1.0),
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
