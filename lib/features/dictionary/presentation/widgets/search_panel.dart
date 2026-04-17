import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(12);
    final borderColor = theme.colorScheme.outline.withValues(
      alpha: isDark ? 0.55 : 0.4,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final showClearButton = value.text.isNotEmpty;
        final iOSTrailing = SizedBox.square(
          dimension: 28,
          child: showClearButton
              ? IconButton(
                  tooltip: l10n.clearSearch,
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                )
              : const SizedBox.shrink(),
        );
        final materialDecoration = InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: showClearButton
              ? IconButton(
                  tooltip: l10n.clearSearch,
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainer,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: AdaptiveTextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            placeholder: l10n.searchHint,
            decoration: PlatformInfo.isIOS ? null : materialDecoration,
            prefixIcon: PlatformInfo.isIOS ? const Icon(Icons.search) : null,
            suffix: PlatformInfo.isIOS ? iOSTrailing : null,
            suffixIcon: PlatformInfo.isIOS
                ? null
                : null,
          ),
        );
      },
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
