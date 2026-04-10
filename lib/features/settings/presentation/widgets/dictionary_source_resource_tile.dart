import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/dictionary/data/offline_dictionary_library.dart';
import 'package:taigi_dict/offline_audio.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';

class DictionarySourceResourceTile extends StatelessWidget {
  const DictionarySourceResourceTile({
    super.key,
    required this.dictionaryLibrary,
    required this.onDownload,
  });

  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final applePlatform = isApplePlatform(context);
    return ValueListenableBuilder<DownloadSnapshot>(
      valueListenable: dictionaryLibrary.downloadListenable,
      builder: (context, snapshot, child) {
        final progress = snapshot.progress;
        final statusText = switch (snapshot.state) {
          DownloadState.downloading =>
            '${dictionaryLibrary.downloadStatus()} • ${dictionaryLibrary.downloadSpeed()}',
          DownloadState.paused =>
            '${l10n.pause} • ${dictionaryLibrary.downloadStatus()}',
          DownloadState.completed => l10n.dictionarySourceReady,
          DownloadState.error =>
            snapshot.errorMessage ??
                '${l10n.retry} • ${dictionaryLibrary.downloadStatus()}',
          DownloadState.idle => l10n.dictionarySourceSubtitle,
        };

        final actionIcon = switch (snapshot.state) {
          DownloadState.downloading => Icons.pause_circle_filled,
          DownloadState.completed => Icons.check_circle,
          DownloadState.idle ||
          DownloadState.paused ||
          DownloadState.error => Icons.play_circle_fill,
        };

        final actionTooltip = switch (snapshot.state) {
          DownloadState.downloading => l10n.pause,
          DownloadState.completed => l10n.dictionarySourceReady,
          DownloadState.idle => l10n.download,
          DownloadState.paused => l10n.resume,
          DownloadState.error => l10n.retry,
        };

        final onPressed = snapshot.state == DownloadState.completed
            ? null
            : () => onDownload();

        return MergeSemantics(
          child: Semantics(
            container: true,
            label: l10n.semanticsJoined([
              l10n.dictionarySourceArchive,
              dictionaryLibrary.fileName,
              statusText,
            ]),
            value: l10n.semanticsProgressValue(
              snapshot.downloadedBytes,
              snapshot.totalBytes,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Icon(
                Icons.description_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                l10n.dictionarySourceArchive,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dictionaryLibrary.fileName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (progress != null &&
                        snapshot.state != DownloadState.idle) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        minHeight: applePlatform ? 4 : null,
                        value: snapshot.state == DownloadState.completed
                            ? 1
                            : progress,
                        borderRadius: applePlatform
                            ? BorderRadius.circular(999)
                            : null,
                        backgroundColor: applePlatform
                            ? resolveLiquidGlassSecondaryTint(
                                context,
                              ).withValues(alpha: 0.45)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              trailing: AdaptiveSettingsActionButton(
                tooltip: actionTooltip,
                onPressed: onPressed,
                icon: actionIcon,
              ),
            ),
          ),
        );
      },
    );
  }
}
