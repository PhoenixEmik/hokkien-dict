import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';


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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
          if (entry.romanization.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.romanization,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.tertiary,
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
                color: colorScheme.onSurfaceVariant,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            if (entry.audioId.isNotEmpty) ...[
              const SizedBox(width: 12),
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
    return _MaterialSenseSection(
      sense: sense,
      audioLibrary: audioLibrary,
      onPlayClip: onPlayClip,
      onWordTapped: onWordTapped,
      textScale: textScale,
    );
  }
}

class _MaterialSenseSection extends StatelessWidget {
  const _MaterialSenseSection({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sense.partOfSpeech.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MaterialSensePill(label: sense.partOfSpeech),
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
          if (sense.definitionSynonyms.isNotEmpty ||
              sense.definitionAntonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            if (sense.definitionSynonyms.isNotEmpty)
              RelationshipChipGroup(
                label: AppLocalizations.of(context).synonymsLabel,
                values: sense.definitionSynonyms,
                onWordTapped: onWordTapped,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (sense.definitionSynonyms.isNotEmpty &&
                sense.definitionAntonyms.isNotEmpty)
              const SizedBox(height: 12),
            if (sense.definitionAntonyms.isNotEmpty)
              RelationshipChipGroup(
                label: AppLocalizations.of(context).antonymsLabel,
                values: sense.definitionAntonyms,
                onWordTapped: onWordTapped,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                      color: colorScheme.onSurface,
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
                        color: colorScheme.tertiary,
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
                      color: colorScheme.onSurfaceVariant,
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

class _MaterialSensePill extends StatelessWidget {
  const _MaterialSensePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSecondaryContainer,
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
                  color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillColor = colorScheme.surfaceContainerHighest;
    final strokeColor = colorScheme.outlineVariant.withValues(alpha: 0.75);
    final textColor = colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);
    final isInteractive = onTap != null;
    final isMaterialPlatform =
        theme.platform == TargetPlatform.android ||
        theme.platform == TargetPlatform.fuchsia;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      container: true,
      button: isInteractive,
      enabled: isInteractive,
      label: semanticLabel ?? word,
      onTapHint: isInteractive ? l10n.searchThisWordHint : null,
      child: ExcludeSemantics(
        child: isMaterialPlatform
            ? Material(
                color: Colors.transparent,
                child: ActionChip(
                  label: Text(word),
                  onPressed: isInteractive
                      ? () {
                          unawaited(onTap!());
                        }
                      : null,
                  labelStyle: labelStyle,
                  backgroundColor: fillColor,
                  surfaceTintColor: Colors.transparent,
                  side: BorderSide(color: strokeColor, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )
            : Material(
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
                      child: Text(word, style: labelStyle),
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
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            ...lines.map((line) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    line,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );

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
    final mutedColor = theme.colorScheme.onSurfaceVariant;
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
