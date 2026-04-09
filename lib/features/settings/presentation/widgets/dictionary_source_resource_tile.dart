import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

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
              leading: const Icon(
                Icons.description_outlined,
                color: Color(0xFF17454C),
              ),
              title: Text(
                l10n.dictionarySourceArchive,
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
                      dictionaryLibrary.fileName,
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
                        snapshot.state != DownloadState.idle) ...[
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
            ),
          ),
        );
      },
    );
  }
}
