import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';

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
    return ValueListenableBuilder<DownloadSnapshot>(
      valueListenable: dictionaryLibrary.downloadListenable,
      builder: (context, snapshot, child) {
        final progress = snapshot.progress;
        final statusText = switch (snapshot.state) {
          DownloadState.downloading =>
            '${dictionaryLibrary.downloadStatus()} \u2022 ${dictionaryLibrary.downloadSpeed()}',
          DownloadState.paused =>
            '${l10n.pause} \u2022 ${dictionaryLibrary.downloadStatus()}',
          DownloadState.completed => l10n.dictionarySourceReady,
          DownloadState.error =>
            snapshot.errorMessage ??
                '${l10n.retry} \u2022 ${dictionaryLibrary.downloadStatus()}',
          DownloadState.idle => l10n.dictionarySourceSubtitle,
        };

        final actionIcon = switch (snapshot.state) {
          DownloadState.downloading => Icons.pause_circle_filled,
          DownloadState.completed => Icons.check_circle,
          DownloadState.idle => Icons.download_rounded,
          DownloadState.paused => Icons.play_circle_fill,
          DownloadState.error => Icons.download_rounded,
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

        final subtitle = Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dictionaryLibrary.fileName,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(statusText, style: theme.textTheme.bodySmall),
              if (progress != null && snapshot.state != DownloadState.idle) ...[
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
              l10n.dictionarySourceArchive,
              dictionaryLibrary.fileName,
              statusText,
            ]),
            value: l10n.semanticsProgressValue(
              snapshot.downloadedBytes,
              snapshot.totalBytes,
            ),
            child: AdaptiveListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.dictionarySourceArchive),
              subtitle: subtitle,
              trailing: Tooltip(
                message: actionTooltip,
                child: PlatformInfo.isIOS
                    ? AdaptiveButton.sfSymbol(
                        onPressed: onPressed,
                        sfSymbol: SFSymbol(switch (snapshot.state) {
                          DownloadState.downloading => 'pause.circle.fill',
                          DownloadState.completed => 'checkmark.circle.fill',
                          DownloadState.idle => 'arrow.down.circle.fill',
                          DownloadState.paused => 'play.circle.fill',
                          DownloadState.error => 'arrow.clockwise.circle.fill',
                        }, size: 18),
                        style: AdaptiveButtonStyle.plain,
                        size: AdaptiveButtonSize.small,
                        minSize: const Size(34, 34),
                        useSmoothRectangleBorder: false,
                      )
                    : AdaptiveButton.icon(
                        onPressed: onPressed,
                        icon: actionIcon,
                        style: AdaptiveButtonStyle.plain,
                        size: AdaptiveButtonSize.small,
                        minSize: const Size(34, 34),
                        useSmoothRectangleBorder: false,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
