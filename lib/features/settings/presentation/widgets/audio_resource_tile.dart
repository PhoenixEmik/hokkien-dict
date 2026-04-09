import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

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
    return ValueListenableBuilder<DownloadSnapshot>(
      valueListenable: audioLibrary.downloadListenable(type),
      builder: (context, snapshot, child) {
        final isReady = audioLibrary.isArchiveReady(type);
        final progress = snapshot.progress;
        final statusText = switch (snapshot.state) {
          DownloadState.downloading =>
            '${audioLibrary.downloadStatus(type)} • ${audioLibrary.downloadSpeed(type)}',
          DownloadState.paused =>
            '${l10n.pause} • ${audioLibrary.downloadStatus(type)}',
          DownloadState.completed => l10n.downloadReady,
          DownloadState.error =>
            snapshot.errorMessage ??
                '${l10n.retry} • ${audioLibrary.downloadStatus(type)}',
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

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
          leading: Icon(
            type == AudioArchiveType.word
                ? Icons.record_voice_over_outlined
                : Icons.chat_bubble_outline,
            color: const Color(0xFF17454C),
          ),
          title: Text(
            type == AudioArchiveType.word
                ? l10n.audioWordArchive
                : l10n.audioSentenceArchive,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF18363C),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${type.archiveFileName} • ${formatBytes(type.archiveBytes)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66797D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5A6D71),
                  ),
                ),
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
          ),
          trailing: IconButton.filledTonal(
            tooltip: actionTooltip,
            onPressed: onPressed,
            icon: Icon(actionIcon),
          ),
        );
      },
    );
  }
}
