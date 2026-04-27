import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
        child: _AdaptiveAudioActionButton(
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

class _AdaptiveAudioActionButton extends StatelessWidget {
  const _AdaptiveAudioActionButton({
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
    final size = compact ? AdaptiveButtonSize.small : AdaptiveButtonSize.medium;
    final minSize = compact ? const Size(40, 40) : const Size(48, 48);
    final style = PlatformInfo.isIOS
        ? AdaptiveButtonStyle.gray
        : AdaptiveButtonStyle.tinted;

    if (isLoading) {
      return AdaptiveButton.child(
        onPressed: null,
        enabled: false,
        style: style,
        size: size,
        minSize: minSize,
        useSmoothRectangleBorder: false,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }

    if (PlatformInfo.isIOS) {
      return AdaptiveButton.sfSymbol(
        onPressed: onPressed,
        sfSymbol: SFSymbol(
          isPlaying
              ? 'stop.circle'
              : archiveReady
              ? 'speaker.wave.2'
              : 'arrow.down.circle',
          size: compact ? 18 : 20,
        ),
        style: style,
        size: size,
        minSize: minSize,
        useSmoothRectangleBorder: false,
      );
    }

    return AdaptiveButton.icon(
      onPressed: onPressed,
      icon: isPlaying
          ? Icons.stop_circle_outlined
          : archiveReady
          ? Icons.volume_up_outlined
          : Icons.download_outlined,
      style: style,
      size: size,
      minSize: minSize,
      useSmoothRectangleBorder: false,
    );
  }
}
