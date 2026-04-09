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
    final isReady = audioLibrary.isArchiveReady(type);
    final isDownloading = audioLibrary.isDownloading(type);
    final progress = audioLibrary.downloadProgress(type);
    final statusText = isDownloading
        ? audioLibrary.downloadStatus(type)
        : isReady
        ? l10n.downloadReady
        : l10n.downloadApproximateSize(formatBytes(type.archiveBytes));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
              type.archiveFileName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF66797D)),
            ),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6D71)),
            ),
            if (isDownloading && progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        onPressed: isDownloading ? null : () => onDownload(type),
        child: isDownloading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isReady ? l10n.redownload : l10n.download),
      ),
    );
  }
}
