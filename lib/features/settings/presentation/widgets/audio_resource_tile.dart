import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/offline_audio.dart';

class AudioResourceTile extends StatelessWidget {
  const AudioResourceTile({
    super.key,
    required this.type,
    required this.audioLibrary,
    required this.onDownload,
  });

  final AudioArchiveType type;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<DownloadSnapshot>(
      valueListenable: audioLibrary.downloadListenable(type),
      builder: (context, snapshot, child) {
        final isReady = audioLibrary.isArchiveReady(type);
        final titleText = type == AudioArchiveType.word
            ? l10n.audioWordArchive
            : l10n.audioSentenceArchive;
        final progress = snapshot.progress;
        final statusText = switch (snapshot.state) {
          DownloadState.downloading =>
            '${audioLibrary.downloadStatus(type)} \u2022 ${audioLibrary.downloadSpeed(type)}',
          DownloadState.paused =>
            '${l10n.pause} \u2022 ${audioLibrary.downloadStatus(type)}',
          DownloadState.completed => l10n.downloadReady,
          DownloadState.error =>
            snapshot.errorMessage ??
                '${l10n.retry} \u2022 ${audioLibrary.downloadStatus(type)}',
          DownloadState.idle =>
            isReady
                ? l10n.downloadReady
                : l10n.downloadApproximateSize(formatBytes(type.archiveBytes)),
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
          DownloadState.completed => l10n.downloadReady,
          DownloadState.idle => l10n.download,
          DownloadState.paused => l10n.resume,
          DownloadState.error => l10n.retry,
        };

        final onPressed = snapshot.state == DownloadState.completed
            ? null
            : () => onDownload(type);
        final leadingIcon = type == AudioArchiveType.word
            ? Icons.record_voice_over_outlined
            : Icons.chat_bubble_outline;

        final subtitle = Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${type.archiveFileName} \u2022 ${formatBytes(type.archiveBytes)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(statusText, style: theme.textTheme.bodySmall),
              if (progress != null &&
                  (snapshot.state != DownloadState.idle || isReady)) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: snapshot.state == DownloadState.completed
                      ? 1
                      : progress,
                ),
              ],
            ],
          ),
        );

        return MergeSemantics(
          child: Semantics(
            container: true,
            label: l10n.semanticsJoined([
              titleText,
              '${type.archiveFileName} \u2022 ${formatBytes(type.archiveBytes)}',
              statusText,
            ]),
            value: l10n.semanticsProgressValue(
              snapshot.downloadedBytes,
              snapshot.totalBytes > 0 ? snapshot.totalBytes : type.archiveBytes,
            ),
            child: ListTile(
              leading: Icon(leadingIcon),
              title: Text(titleText),
              subtitle: subtitle,
              trailing: IconButton(
                tooltip: actionTooltip,
                onPressed: onPressed,
                icon: Icon(actionIcon),
              ),
            ),
          ),
        );
      },
    );
  }
}
