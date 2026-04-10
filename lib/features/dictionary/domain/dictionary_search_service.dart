import 'package:taigi_dict/features/dictionary/domain/dictionary_models.dart';

List<Map<String, Object>> buildDictionarySearchIndex(
  List<DictionaryEntry> entries,
) {
  return entries
      .map((entry) {
        return <String, Object>{
          'id': entry.id,
          'headwords': _headwordFieldsForEntry(entry),
          'definitions': _definitionFieldsForEntry(entry),
        };
      })
      .toList(growable: false);
}

List<int> searchDictionaryEntryIds(
  List<Map<String, Object>> searchIndex,
  String query,
) {
  final matched = <_ScoredSearchHit>[];
  for (final searchRow in searchIndex) {
    final match = _matchSearchRow(searchRow, query);
    if (match != null) {
      matched.add(match);
    }
  }

  matched.sort((left, right) {
    final comparePriority = left.score.compareTo(right.score);
    if (comparePriority != 0) {
      return comparePriority;
    }

    final compareLength = left.matchedLength.compareTo(right.matchedLength);
    if (compareLength != 0) {
      return compareLength;
    }

    return left.entryId.compareTo(right.entryId);
  });

  return matched.take(60).map((item) => item.entryId).toList(growable: false);
}

_ScoredSearchHit? _matchSearchRow(Map<String, Object> searchRow, String query) {
  final entryId = searchRow['id'] as int;
  final headwordMatch = _bestMatchLength(
    (searchRow['headwords'] as List<Object>).cast<String>(),
    query,
  );
  if (headwordMatch != null) {
    final score = headwordMatch == query.length ? 0 : 1;
    return _ScoredSearchHit(entryId, score, headwordMatch);
  }

  final definitionMatch = _bestMatchLength(
    (searchRow['definitions'] as List<Object>).cast<String>(),
    query,
  );
  if (definitionMatch == null) {
    return null;
  }
  return _ScoredSearchHit(entryId, 2, definitionMatch);
}

List<String> _headwordFieldsForEntry(DictionaryEntry entry) {
  final fields = <String>{};
  final hanji = normalizeQuery(entry.hanji);
  if (hanji.isNotEmpty) {
    fields.add(hanji);
  }
  final romanization = normalizeQuery(entry.romanization);
  if (romanization.isNotEmpty) {
    fields.add(romanization);
  }
  return fields.toList(growable: false);
}

List<String> _definitionFieldsForEntry(DictionaryEntry entry) {
  return entry.senses
      .map((sense) => normalizeQuery(sense.definition))
      .where((definition) => definition.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

int? _bestMatchLength(List<String> fields, String query) {
  int? bestLength;
  for (final field in fields) {
    if (field.isEmpty || query.isEmpty || !field.contains(query)) {
      continue;
    }
    if (bestLength == null || field.length < bestLength) {
      bestLength = field.length;
    }
  }
  return bestLength;
}

class _ScoredSearchHit {
  const _ScoredSearchHit(this.entryId, this.score, this.matchedLength);

  final int entryId;
  final int score;
  final int matchedLength;
}

String normalizeQuery(String input) {
  var normalized = removeTones(input.trim());
  normalized = normalized.replaceAll(RegExp(r'[1-8]'), '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  normalized = normalized.replaceAll(RegExp(r'[-_/]'), ' ');
  normalized = normalized.replaceAll(RegExp("[【】\\[\\]（）()、,.;:!?\"'`]+"), ' ');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String removeTones(String input) {
  var normalized = input.toLowerCase();
  for (final entry in _romanizationFold.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  normalized = normalized.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  normalized = normalized.replaceAll('o͘', 'oo');
  normalized = normalized.replaceAll('ⁿ', 'n');
  normalized = normalized.replaceAll(RegExp(r'[1-8]'), '');
  return normalized;
}

const Map<String, String> _romanizationFold = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ǎ': 'a',
  'ā': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ē': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ī': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ō': 'o',
  'ö': 'o',
  'ő': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ū': 'u',
  'ü': 'u',
  'ḿ': 'm',
  'm̀': 'm',
  'm̂': 'm',
  'ń': 'n',
  'ǹ': 'n',
  'n̂': 'n',
};
