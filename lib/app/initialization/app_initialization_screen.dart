import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/app/initialization/app_initialization_controller.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/dictionary/data/offline_dictionary_library.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

class AppInitializationScreen extends StatelessWidget {
  const AppInitializationScreen({
    super.key,
    required this.controller,
    required this.dictionaryLibrary,
    required this.onRetry,
  });

  final AppInitializationController controller;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final applePlatform = isApplePlatform(context);
    return applePlatform
        ? _AppleInitializationScreen(
            controller: controller,
            dictionaryLibrary: dictionaryLibrary,
            onRetry: onRetry,
          )
        : _MaterialInitializationScreen(
            controller: controller,
            dictionaryLibrary: dictionaryLibrary,
            onRetry: onRetry,
          );
  }
}

class _AppleInitializationScreen extends StatelessWidget {
  const _AppleInitializationScreen({
    required this.controller,
    required this.dictionaryLibrary,
    required this.onRetry,
  });

  final AppInitializationController controller;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = controller.progress;
    final isError = controller.phase == AppInitializationPhase.error;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: LiquidGlassSection(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AppleInitializationIcon(isError: isError),
                          const SizedBox(height: 24),
                          Text(
                            l10n.initializingAppTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: resolveLiquidGlassForeground(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _headlineText(l10n),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: resolveLiquidGlassForeground(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              _detailText(l10n),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: resolveLiquidGlassSecondaryForeground(
                                  context,
                                ),
                                height: 1.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _AppleProgressBar(value: isError ? null : progress),
                          const SizedBox(height: 12),
                          Text(
                            _progressText(l10n),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: resolveLiquidGlassSecondaryForeground(
                                context,
                              ),
                            ),
                          ),
                          if (isError) ...[
                            const SizedBox(height: 24),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              color: resolveLiquidGlassTint(context),
                              borderRadius: BorderRadius.circular(18),
                              onPressed: () {
                                onRetry();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.refresh,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.retryInitialization,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _headlineText(AppLocalizations l10n) {
    return switch (controller.phase) {
      AppInitializationPhase.checking => l10n.initializationCheckingResources,
      AppInitializationPhase.downloadingSource =>
        l10n.initializationDownloadingSource,
      AppInitializationPhase.parsingSource => l10n.initializationParsingSource,
      AppInitializationPhase.writingDatabase =>
        l10n.initializationWritingDatabase,
      AppInitializationPhase.finalizingDatabase =>
        l10n.initializationFinalizingDatabase,
      AppInitializationPhase.error => l10n.initializationFailed,
      AppInitializationPhase.ready => l10n.dictionaryTab,
      AppInitializationPhase.idle => l10n.initializationCheckingResources,
    };
  }

  String _detailText(AppLocalizations l10n) {
    if (controller.phase == AppInitializationPhase.error) {
      return controller.describeError(l10n);
    }

    if (controller.phase == AppInitializationPhase.downloadingSource) {
      final status = dictionaryLibrary.downloadStatus();
      final speed = dictionaryLibrary.downloadSpeed();
      return l10n.initializationDownloadProgress(status, speed);
    }

    return l10n.initializationBlockingNotice;
  }

  String _progressText(AppLocalizations l10n) {
    return switch (controller.phase) {
      AppInitializationPhase.parsingSource => l10n.initializationParsingRows(
        controller.processedUnits,
        controller.totalUnits,
      ),
      AppInitializationPhase.writingDatabase => l10n.initializationWritingRows(
        controller.processedUnits,
        controller.totalUnits,
      ),
      AppInitializationPhase.downloadingSource =>
        l10n.initializationDownloadingSource,
      AppInitializationPhase.finalizingDatabase =>
        l10n.initializationFinalizingDatabase,
      AppInitializationPhase.error => l10n.initializationRetryHint,
      _ => l10n.initializationCheckingResources,
    };
  }
}

class _MaterialInitializationScreen extends StatelessWidget {
  const _MaterialInitializationScreen({
    required this.controller,
    required this.dictionaryLibrary,
    required this.onRetry,
  });

  final AppInitializationController controller;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = controller.progress;
    final isError = controller.phase == AppInitializationPhase.error;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        isError ? Icons.warning_amber_rounded : Icons.storage,
                        size: 34,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.initializingAppTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _headlineText(l10n),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _detailText(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(value: isError ? null : progress),
                    const SizedBox(height: 12),
                    Text(
                      _progressText(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isError) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          onRetry();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retryInitialization),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _headlineText(AppLocalizations l10n) {
    return switch (controller.phase) {
      AppInitializationPhase.checking => l10n.initializationCheckingResources,
      AppInitializationPhase.downloadingSource =>
        l10n.initializationDownloadingSource,
      AppInitializationPhase.parsingSource => l10n.initializationParsingSource,
      AppInitializationPhase.writingDatabase =>
        l10n.initializationWritingDatabase,
      AppInitializationPhase.finalizingDatabase =>
        l10n.initializationFinalizingDatabase,
      AppInitializationPhase.error => l10n.initializationFailed,
      AppInitializationPhase.ready => l10n.dictionaryTab,
      AppInitializationPhase.idle => l10n.initializationCheckingResources,
    };
  }

  String _detailText(AppLocalizations l10n) {
    if (controller.phase == AppInitializationPhase.error) {
      return controller.describeError(l10n);
    }

    if (controller.phase == AppInitializationPhase.downloadingSource) {
      final status = dictionaryLibrary.downloadStatus();
      final speed = dictionaryLibrary.downloadSpeed();
      return l10n.initializationDownloadProgress(status, speed);
    }

    return l10n.initializationBlockingNotice;
  }

  String _progressText(AppLocalizations l10n) {
    return switch (controller.phase) {
      AppInitializationPhase.parsingSource => l10n.initializationParsingRows(
        controller.processedUnits,
        controller.totalUnits,
      ),
      AppInitializationPhase.writingDatabase => l10n.initializationWritingRows(
        controller.processedUnits,
        controller.totalUnits,
      ),
      AppInitializationPhase.downloadingSource =>
        l10n.initializationDownloadingSource,
      AppInitializationPhase.finalizingDatabase =>
        l10n.initializationFinalizingDatabase,
      AppInitializationPhase.error => l10n.initializationRetryHint,
      _ => l10n.initializationCheckingResources,
    };
  }
}

class _AppleInitializationIcon extends StatelessWidget {
  const _AppleInitializationIcon({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError
        ? CupertinoColors.systemOrange
        : resolveLiquidGlassTint(context);
    final brightness = Theme.of(context).brightness;
    final fillColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.24);
    final borderColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fillColor.withValues(alpha: fillColor.a * 1.08),
                fillColor,
              ],
            ),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Icon(
            isError
                ? CupertinoIcons.exclamationmark_triangle
                : CupertinoIcons.doc_text_search,
            size: 40,
            color: tint,
          ),
        ),
      ),
    );
  }
}

class _AppleProgressBar extends StatelessWidget {
  const _AppleProgressBar({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final trackColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    final fillColor = resolveLiquidGlassTint(context);

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }
}
