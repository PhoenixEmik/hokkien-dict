import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';

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
    final isLoading = audioLibrary.isClipLoading(type, audioId);
    final isPlaying = audioLibrary.isClipPlaying(type, audioId);
    final archiveReady = audioLibrary.isArchiveReady(type);
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
        child: _AudioActionButton(
          isLoading: isLoading,
          isPlaying: isPlaying,
          archiveReady: archiveReady,
          compact: compact,
          onPressed: isLoading ? null : () => onPressed(type, audioId),
        ),
      ),
    );
  }
}

class _AudioActionButton extends StatelessWidget {
  const _AudioActionButton({
    required this.isLoading,
    required this.isPlaying,
    required this.archiveReady,
    required this.compact,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isPlaying;
  final bool archiveReady;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 40.0 : 48.0;
    final iconSize = compact ? 18.0 : 20.0;
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;

    return SizedBox.square(
      dimension: dimension,
      child: IconButton.filledTonal(
        onPressed: isLoading ? null : onPressed,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.square(dimension),
          maximumSize: Size.square(dimension),
          iconSize: iconSize,
          side: BorderSide(color: outlineColor, width: 1),
        ),
        icon: isLoading
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
              ),
      ),
    );
  }
}
