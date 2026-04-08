import 'package:flutter/material.dart';

import '../../../../offline_audio.dart';
import '../../domain/dictionary_models.dart';
import 'audio_button.dart';

class WordDetailHeader extends StatelessWidget {
  const WordDetailHeader({
    super.key,
    required this.entry,
    required this.audioLibrary,
    required this.onPlayClip,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (entry.type.isNotEmpty) entry.type,
      if (entry.category.isNotEmpty) entry.category,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        entry.hanji.isEmpty ? '未標記漢字' : entry.hanji,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E2F35),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.romanization.isNotEmpty)
            Text(
              entry.romanization,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFFC9752D),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF54696D),
              ),
            ),
          ],
        ],
      ),
      trailing: entry.audioId.isEmpty
          ? null
          : AudioButton(
              type: AudioArchiveType.word,
              audioId: entry.audioId,
              audioLibrary: audioLibrary,
              onPressed: onPlayClip,
            ),
    );
  }
}

class SenseSection extends StatelessWidget {
  const SenseSection({
    super.key,
    required this.sense,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.textScale,
  });

  final DictionarySense sense;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sense.partOfSpeech.isNotEmpty)
                Chip(label: Text(sense.partOfSpeech)),
              if (sense.definition.isNotEmpty)
                Text(
                  sense.definition,
                  style: scaledTextStyle(
                    theme.textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                    ),
                    textScale,
                  ),
                ),
            ],
          ),
          if (sense.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...sense.examples.take(3).map((example) {
              return ExampleListTile(
                example: example,
                audioLibrary: audioLibrary,
                onPlayClip: onPlayClip,
                textScale: textScale,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class ExampleListTile extends StatelessWidget {
  const ExampleListTile({
    super.key,
    required this.example,
    required this.audioLibrary,
    required this.onPlayClip,
    required this.textScale,
  });

  final DictionaryExample example;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFF7F2E8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: example.hanji.isEmpty
            ? null
            : Text(
                example.hanji,
                style: scaledTextStyle(
                  theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textScale,
                ),
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (example.romanization.isNotEmpty)
              Text(
                example.romanization,
                style: scaledTextStyle(
                  theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B5C3A),
                  ),
                  textScale,
                ),
              ),
            if (example.mandarin.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                example.mandarin,
                style: scaledTextStyle(
                  theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF35545B),
                    height: 1.5,
                  ),
                  textScale,
                ),
              ),
            ],
          ],
        ),
        trailing: example.audioId.isEmpty
            ? null
            : AudioButton(
                type: AudioArchiveType.sentence,
                audioId: example.audioId,
                audioLibrary: audioLibrary,
                onPressed: onPlayClip,
                compact: true,
              ),
      ),
    );
  }
}

TextStyle? scaledTextStyle(TextStyle? style, double scale) {
  if (style == null || style.fontSize == null) {
    return style;
  }
  return style.copyWith(fontSize: style.fontSize! * scale);
}
