class DictionaryBundle {
  const DictionaryBundle({
    required this.entryCount,
    required this.senseCount,
    required this.exampleCount,
    required this.entries,
  });

  factory DictionaryBundle.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionaryEntry.fromJson)
        .toList(growable: false);
    return DictionaryBundle(
      entryCount: json['entryCount'] as int,
      senseCount: json['senseCount'] as int,
      exampleCount: json['exampleCount'] as int,
      entries: entries,
    );
  }

  final int entryCount;
  final int senseCount;
  final int exampleCount;
  final List<DictionaryEntry> entries;
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.type,
    required this.hanji,
    required this.romanization,
    required this.category,
    required this.audioId,
    required this.hokkienSearch,
    required this.mandarinSearch,
    this.variantChars = const [],
    this.wordSynonyms = const [],
    this.wordAntonyms = const [],
    required this.senses,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final senses = (json['senses'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionarySense.fromJson)
        .toList(growable: false);
    return DictionaryEntry(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      hanji: json['hanji'] as String? ?? '',
      romanization: json['romanization'] as String? ?? '',
      category: json['category'] as String? ?? '',
      audioId: json['audio'] as String? ?? '',
      hokkienSearch: json['hokkienSearch'] as String? ?? '',
      mandarinSearch: json['mandarinSearch'] as String? ?? '',
      variantChars: _stringListFromJson(json['variantChars']),
      wordSynonyms: _stringListFromJson(json['wordSynonyms']),
      wordAntonyms: _stringListFromJson(json['wordAntonyms']),
      senses: senses,
    );
  }

  final int id;
  final String type;
  final String hanji;
  final String romanization;
  final String category;
  final String audioId;
  final String hokkienSearch;
  final String mandarinSearch;
  final List<String> variantChars;
  final List<String> wordSynonyms;
  final List<String> wordAntonyms;
  final List<DictionarySense> senses;

  String get briefSummary {
    for (final sense in senses) {
      if (sense.definition.isNotEmpty) {
        return sense.definition;
      }
    }

    if (category.isNotEmpty) {
      return category;
    }

    if (type.isNotEmpty) {
      return type;
    }

    return romanization;
  }
}

class DictionarySense {
  const DictionarySense({
    required this.partOfSpeech,
    required this.definition,
    this.definitionSynonyms = const [],
    this.definitionAntonyms = const [],
    required this.examples,
  });

  factory DictionarySense.fromJson(Map<String, dynamic> json) {
    final examples = (json['examples'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DictionaryExample.fromJson)
        .toList(growable: false);
    return DictionarySense(
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      definitionSynonyms: _stringListFromJson(json['definitionSynonyms']),
      definitionAntonyms: _stringListFromJson(json['definitionAntonyms']),
      examples: examples,
    );
  }

  final String partOfSpeech;
  final String definition;
  final List<String> definitionSynonyms;
  final List<String> definitionAntonyms;
  final List<DictionaryExample> examples;
}

class DictionaryExample {
  const DictionaryExample({
    required this.hanji,
    required this.romanization,
    required this.mandarin,
    required this.audioId,
  });

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      hanji: json['hanji'] as String? ?? '',
      romanization: json['romanization'] as String? ?? '',
      mandarin: json['mandarin'] as String? ?? '',
      audioId: json['audio'] as String? ?? '',
    );
  }

  final String hanji;
  final String romanization;
  final String mandarin;
  final String audioId;
}

List<String> _stringListFromJson(dynamic value) {
  if (value is! List<dynamic>) {
    return const [];
  }
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
