import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/offline_audio.dart';

class AudioButton extends StatelessWidget {
  const AudioButton({
    super.key,
    required this.type,
    required this.audioId,
    required this.audioLibrary,
    required this.onPressed,
    this.compact = false,
  });

  final AudioArchiveType type;
  final String audioId;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final applePlatform = isApplePlatform(context);
    final isLoading = audioLibrary.isClipLoading(type, audioId);
    final isPlaying = audioLibrary.isClipPlaying(type, audioId);
    final archiveReady = audioLibrary.isArchiveReady(type);
    const buttonSize = 48.0;
    final clipLabel = type == AudioArchiveType.word
        ? l10n.audioWordArchive
        : l10n.audioSentenceArchive;
    final actionLabel = switch ((isLoading, isPlaying, archiveReady)) {
      (true, _, _) => l10n.loadingAudio(clipLabel),
      (false, true, _) => l10n.stopAudio(clipLabel),
      (false, false, true) => l10n.playAudio(clipLabel),
      (false, false, false) => l10n.downloadAudio(clipLabel),
    };

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: actionLabel,
      child: Tooltip(
        message: actionLabel,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: applePlatform
              ? AdaptiveCircleButton(
                  tooltip: actionLabel,
                  onPressed: () => onPressed(type, audioId),
                  enabled: !isLoading,
                  size: buttonSize,
                  iconSize: compact ? 20 : 22,
                  icon: isPlaying
                      ? CupertinoIcons.stop_circle
                      : archiveReady
                      ? CupertinoIcons.speaker_2_fill
                      : CupertinoIcons.arrow_down_circle,
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              resolveAdaptiveCircleButtonIconColor(context),
                            ),
                          ),
                        )
                      : null,
                )
              : FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: isLoading ? null : () => onPressed(type, audioId),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : archiveReady
                              ? Icons.volume_up_outlined
                              : Icons.download_outlined,
                          size: compact ? 20 : 22,
                        ),
                ),
        ),
      ),
    );
  }
}
