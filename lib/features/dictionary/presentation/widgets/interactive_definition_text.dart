import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';

class InteractiveDefinitionText extends StatefulWidget {
  const InteractiveDefinitionText({
    super.key,
    required this.text,
    required this.onWordTapped,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final Future<void> Function(String word) onWordTapped;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<InteractiveDefinitionText> createState() =>
      _InteractiveDefinitionTextState();
}

class _InteractiveDefinitionTextState extends State<InteractiveDefinitionText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final baseStyle = widget.style ?? theme.textTheme.bodyLarge;
    final actionableStyle = baseStyle?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w700,
    );

    return Text.rich(
      textAlign: widget.textAlign,
      TextSpan(
        style: baseStyle,
        children: _buildDefinitionSpans(
          widget.text,
          l10n: l10n,
          actionableStyle: actionableStyle,
        ),
      ),
    );
  }

  List<InlineSpan> _buildDefinitionSpans(
    String text, {
    required AppLocalizations l10n,
    required TextStyle? actionableStyle,
  }) {
    final spans = <InlineSpan>[];
    for (final segment in parseDefinitionSegments(text)) {
      if (!segment.isActionable) {
        spans.add(TextSpan(text: segment.displayText));
        continue;
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          unawaited(widget.onWordTapped(segment.actionWord));
        };
      _recognizers.add(recognizer);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Semantics(
            button: true,
            link: true,
            label: l10n.linkedDefinitionWordLabel(segment.actionWord),
            child: GestureDetector(
              onTap: recognizer.onTap,
              child: ExcludeSemantics(
                child: Text(segment.displayText, style: actionableStyle),
              ),
            ),
          ),
        ),
      );
    }
    return spans;
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}

List<DefinitionTextSegment> parseDefinitionSegments(String text) {
  if (text.isEmpty) {
    return const <DefinitionTextSegment>[];
  }

  final matches = RegExp(r'【([^】]+)】').allMatches(text).toList(growable: false);
  if (matches.isEmpty) {
    return <DefinitionTextSegment>[DefinitionTextSegment.plain(text)];
  }

  final segments = <DefinitionTextSegment>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      segments.add(
        DefinitionTextSegment.plain(text.substring(cursor, match.start)),
      );
    }

    final actionWord = (match.group(1) ?? '').trim();
    final displayText = match.group(0) ?? '';
    if (actionWord.isEmpty) {
      segments.add(DefinitionTextSegment.plain(displayText));
    } else {
      segments.add(
        DefinitionTextSegment.actionable(
          displayText: displayText,
          actionWord: actionWord,
        ),
      );
    }
    cursor = match.end;
  }

  if (cursor < text.length) {
    segments.add(DefinitionTextSegment.plain(text.substring(cursor)));
  }

  return segments;
}

class DefinitionTextSegment {
  const DefinitionTextSegment._({
    required this.displayText,
    required this.actionWord,
    required this.isActionable,
  });

  const DefinitionTextSegment.plain(String text)
    : this._(displayText: text, actionWord: '', isActionable: false);

  const DefinitionTextSegment.actionable({
    required String displayText,
    required String actionWord,
  }) : this._(
         displayText: displayText,
         actionWord: actionWord,
         isActionable: true,
       );

  final String displayText;
  final String actionWord;
  final bool isActionable;
}
