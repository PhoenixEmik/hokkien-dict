import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/app/initialization/app_initialization_controller.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';

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
