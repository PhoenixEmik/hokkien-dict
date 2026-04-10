import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/dictionary/domain/dictionary_models.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:hokkien_dictionary/offline_audio.dart';
import 'audio_button.dart';
import 'interactive_definition_text.dart';

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
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final applePlatform = isApplePlatform(context);
    final subtitle = [
      if (entry.type.isNotEmpty) entry.type,
      if (entry.category.isNotEmpty) entry.category,
    ].join(' · ');

    final content = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.hanji.isEmpty ? l10n.unlabeledHanji : entry.hanji,
            style:
                (applePlatform
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: applePlatform
                          ? resolveLiquidGlassForeground(context)
                          : colorScheme.primary,
                    ),
          ),
          if (entry.romanization.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.romanization,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: applePlatform
                      ? resolveLiquidGlassTint(context)
                      : colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: applePlatform
                    ? resolveLiquidGlassSecondaryForeground(context)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    if (applePlatform) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: LiquidGlassSection(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  if (entry.audioId.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    AudioButton(
                      type: AudioArchiveType.word,
                      audioId: entry.audioId,
                      audioLibrary: audioLibrary,
                      onPressed: onPlayClip,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      titleAlignment: ListTileTitleAlignment.top,
      title: content,
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
    required this.onWordTapped,
    required this.textScale,
  });

  final DictionarySense sense;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applePlatform = isApplePlatform(context);
    const appleInset = 20.0;
    final sectionChildren = <Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(
          applePlatform ? appleInset : 0,
          applePlatform ? 18 : 0,
          applePlatform ? appleInset : 0,
          applePlatform ? 18 : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sense.partOfSpeech.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: applePlatform
                    ? _SensePill(label: sense.partOfSpeech)
                    : Chip(
                        label: Text(sense.partOfSpeech),
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            if (sense.definition.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: InteractiveDefinitionText(
                  text: sense.definition,
                  onWordTapped: onWordTapped,
                  textAlign: TextAlign.left,
                  style: scaledTextStyle(
                    theme.textTheme.bodyLarge?.copyWith(
                      height: applePlatform ? 1.6 : 1.55,
                      fontWeight: FontWeight.w700,
                      color: applePlatform
                          ? resolveLiquidGlassForeground(context)
                          : null,
                    ),
                    textScale,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];

    if (sense.examples.isNotEmpty) {
      sectionChildren.addAll(
        sense.examples.take(3).map((example) {
          return ExampleListTile(
            example: example,
            audioLibrary: audioLibrary,
            onPlayClip: onPlayClip,
            textScale: textScale,
          );
        }),
      );
    }

    if (applePlatform) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LiquidGlassSection(
          dividerIndent: appleInset,
          dividerEndIndent: appleInset,
          children: sectionChildren,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sense.partOfSpeech.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: Text(sense.partOfSpeech),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (sense.definition.isNotEmpty)
            InteractiveDefinitionText(
              text: sense.definition,
              onWordTapped: onWordTapped,
              style: scaledTextStyle(
                theme.textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
                textScale,
              ),
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
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final applePlatform = isApplePlatform(context);
    final mergedSemanticsLabel = [
      if (example.hanji.isNotEmpty) example.hanji,
      if (example.romanization.isNotEmpty)
        l10n.romanizationLabel(example.romanization),
      if (example.mandarin.isNotEmpty) l10n.mandarinLabel(example.mandarin),
    ];

    final content = MergeSemantics(
      child: Semantics(
        label: mergedSemanticsLabel.isEmpty
            ? null
            : l10n.semanticsJoined(mergedSemanticsLabel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (example.hanji.isNotEmpty)
              ExcludeSemantics(
                child: Text(
                  example.hanji,
                  style: scaledTextStyle(
                    theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: applePlatform
                          ? resolveLiquidGlassForeground(context)
                          : colorScheme.onSurface,
                    ),
                    textScale,
                  ),
                ),
              ),
            if (example.romanization.isNotEmpty)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    example.romanization,
                    style: scaledTextStyle(
                      theme.textTheme.bodyMedium?.copyWith(
                        color: applePlatform
                            ? resolveLiquidGlassTint(context)
                            : colorScheme.tertiary,
                      ),
                      textScale,
                    ),
                  ),
                ),
              ),
            if (example.mandarin.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  example.mandarin,
                  style: scaledTextStyle(
                    theme.textTheme.bodyMedium?.copyWith(
                      color: applePlatform
                          ? resolveLiquidGlassSecondaryForeground(context)
                          : colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textScale,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (applePlatform) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            if (example.audioId.isNotEmpty) ...[
              const SizedBox(width: 14),
              AudioButton(
                type: AudioArchiveType.sentence,
                audioId: example.audioId,
                audioLibrary: audioLibrary,
                onPressed: onPlayClip,
                compact: true,
              ),
            ],
          ],
        ),
      );
    }

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: content,
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

class _SensePill extends StatelessWidget {
  const _SensePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolveLiquidGlassSecondaryTint(context).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: resolveLiquidGlassForeground(context),
          ),
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
