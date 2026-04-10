import 'dart:async';

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
    required this.onWordTapped,
  });

  final DictionaryEntry entry;
  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type, String clipId) onPlayClip;
  final Future<void> Function(String word) onWordTapped;

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
          if (entry.alternativePronunciations.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PronunciationNoteLine(
              label: l10n.alternativePronunciationLabel,
              values: entry.alternativePronunciations,
            ),
          ],
          if (entry.contractedPronunciations.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PronunciationNoteLine(
              label: l10n.contractedPronunciationLabel,
              values: entry.contractedPronunciations,
            ),
          ],
          if (entry.colloquialPronunciations.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PronunciationNoteLine(
              label: l10n.colloquialPronunciationLabel,
              values: entry.colloquialPronunciations,
            ),
          ],
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
          if (entry.variantChars.isNotEmpty) ...[
            const SizedBox(height: 14),
            RelationshipChipGroup(
              label: l10n.variantCharactersLabel,
              values: entry.variantChars,
            ),
          ],
          if (entry.wordSynonyms.isNotEmpty) ...[
            const SizedBox(height: 14),
            RelationshipChipGroup(
              label: l10n.synonymsLabel,
              values: entry.wordSynonyms,
              onWordTapped: onWordTapped,
            ),
          ],
          if (entry.wordAntonyms.isNotEmpty) ...[
            const SizedBox(height: 14),
            RelationshipChipGroup(
              label: l10n.antonymsLabel,
              values: entry.wordAntonyms,
              onWordTapped: onWordTapped,
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
    final brightness = theme.brightness;
    final applePlatform = isApplePlatform(context);
    final relationshipDividerColor = brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.15);
    final relationshipLabelColor = brightness == Brightness.light
        ? Colors.grey.shade600
        : Colors.grey.shade400;
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

    if (sense.definitionSynonyms.isNotEmpty ||
        sense.definitionAntonyms.isNotEmpty) {
      sectionChildren.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            applePlatform ? appleInset : 0,
            0,
            applePlatform ? appleInset : 0,
            applePlatform ? 18 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(
                height: 1,
                thickness: 0.5,
                color: relationshipDividerColor,
              ),
              if (sense.definitionSynonyms.isNotEmpty)
                RelationshipChipGroup(
                  label: AppLocalizations.of(context).synonymsLabel,
                  values: sense.definitionSynonyms,
                  onWordTapped: onWordTapped,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: relationshipLabelColor,
                  ),
                  labelPadding: const EdgeInsets.only(top: 12, bottom: 8),
                  wrapAlignment: WrapAlignment.start,
                ),
              if (sense.definitionSynonyms.isNotEmpty &&
                  sense.definitionAntonyms.isNotEmpty)
                const SizedBox(height: 10),
              if (sense.definitionAntonyms.isNotEmpty)
                RelationshipChipGroup(
                  label: AppLocalizations.of(context).antonymsLabel,
                  values: sense.definitionAntonyms,
                  onWordTapped: onWordTapped,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: relationshipLabelColor,
                  ),
                  labelPadding: const EdgeInsets.only(top: 12, bottom: 8),
                  wrapAlignment: WrapAlignment.start,
                ),
            ],
          ),
        ),
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
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.15);
    final foregroundColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class RelationshipChipGroup extends StatelessWidget {
  const RelationshipChipGroup({
    super.key,
    required this.label,
    required this.values,
    this.onWordTapped,
    this.labelStyle,
    this.labelPadding = const EdgeInsets.only(bottom: 8),
    this.wrapAlignment = WrapAlignment.start,
    this.semanticLabelBuilder,
  });

  final String label;
  final List<String> values;
  final Future<void> Function(String word)? onWordTapped;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry labelPadding;
  final WrapAlignment wrapAlignment;
  final String Function(BuildContext context, String word)?
  semanticLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uniqueValues = values.toSet().toList(growable: false);
    if (uniqueValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: labelPadding,
          child: Text(
            label,
            textAlign: TextAlign.left,
            style:
                labelStyle ??
                theme.textTheme.labelLarge?.copyWith(
                  color: isApplePlatform(context)
                      ? resolveLiquidGlassSecondaryForeground(context)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Wrap(
          alignment: wrapAlignment,
          spacing: 8,
          runSpacing: 8,
          children: uniqueValues
              .map(
                (value) => RelationshipChip(
                  word: value,
                  semanticLabel: semanticLabelBuilder?.call(context, value),
                  onTap: onWordTapped == null
                      ? null
                      : () => onWordTapped!(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class RelationshipChip extends StatelessWidget {
  const RelationshipChip({
    super.key,
    required this.word,
    this.semanticLabel,
    this.onTap,
  });

  final String word;
  final String? semanticLabel;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fillColor = brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.18);
    final strokeColor = brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.15);
    final textColor = isApplePlatform(context)
        ? resolveLiquidGlassForeground(context)
        : Theme.of(context).colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);
    final isInteractive = onTap != null;

    return Semantics(
      container: true,
      button: isInteractive,
      enabled: isInteractive,
      label: semanticLabel ?? word,
      onTapHint: isInteractive ? l10n.searchThisWordHint : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isInteractive
                ? () {
                    unawaited(onTap!());
                  }
                : null,
            child: Ink(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: strokeColor, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  word,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailNoteCard extends StatelessWidget {
  const DetailNoteCard({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final applePlatform = isApplePlatform(context);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: applePlatform
                  ? resolveLiquidGlassForeground(context)
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: applePlatform
                      ? resolveLiquidGlassSecondaryForeground(context)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ],
      ),
    );

    if (applePlatform) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LiquidGlassSection(children: [content]),
      );
    }

    return Card(margin: const EdgeInsets.only(bottom: 16), child: content);
  }
}

class _PronunciationNoteLine extends StatelessWidget {
  const _PronunciationNoteLine({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = isApplePlatform(context)
        ? resolveLiquidGlassSecondaryForeground(context)
        : theme.colorScheme.onSurfaceVariant;
    final text = '$label：${values.join('、')}';

    return Text(
      text,
      textAlign: TextAlign.left,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: mutedColor,
        height: 1.45,
        fontWeight: FontWeight.w600,
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
