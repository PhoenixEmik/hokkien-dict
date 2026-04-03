import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hokkien_dictionary/main.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

void main() {
  test('dictionary repository returns no entries for non-matching query', () {
    const bundle = DictionaryBundle(
      entryCount: 2,
      senseCount: 2,
      exampleCount: 0,
      entries: [
        DictionaryEntry(
          id: 1,
          type: '',
          hanji: '一',
          romanization: 'tsit',
          category: '',
          audioId: '',
          hokkienSearch: '一 tsit',
          mandarinSearch: '數字 一',
          senses: [
            DictionarySense(
              partOfSpeech: '',
              definition: '數字一',
              examples: [],
            ),
          ],
        ),
        DictionaryEntry(
          id: 2,
          type: '',
          hanji: '狗',
          romanization: 'kau',
          category: '',
          audioId: '',
          hokkienSearch: '狗 kau',
          mandarinSearch: '動物 狗',
          senses: [
            DictionarySense(
              partOfSpeech: '',
              definition: '狗',
              examples: [],
            ),
          ],
        ),
      ],
    );

    final repository = DictionaryRepository();

    expect(
      repository.search(
        bundle,
        SearchDirection.hokkienToMandarin,
        '人人人',
      ),
      isEmpty,
    );
    expect(
      repository.search(
        bundle,
        SearchDirection.mandarinToHokkien,
        '人人人',
      ),
      isEmpty,
    );
  });

  testWidgets('dictionary screen only renders filtered matches', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDictionaryRepository(
      DictionaryBundle(
        entryCount: 2,
        senseCount: 2,
        exampleCount: 0,
        entries: const [
          DictionaryEntry(
            id: 1,
            type: '',
            hanji: '一',
            romanization: 'tsit',
            category: '',
            audioId: '',
            hokkienSearch: '一 tsit',
            mandarinSearch: '數字 一',
            senses: [
              DictionarySense(
                partOfSpeech: '',
                definition: '數字一',
                examples: [],
              ),
            ],
          ),
          DictionaryEntry(
            id: 2,
            type: '',
            hanji: '狗',
            romanization: 'kau',
            category: '',
            audioId: '',
            hokkienSearch: '狗 kau',
            mandarinSearch: '動物 狗',
            senses: [
              DictionarySense(
                partOfSpeech: '',
                definition: '狗',
                examples: [],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryScreen(
            repository: repository,
            audioLibrary: OfflineAudioLibrary(),
            searchBarPlacement: SearchBarPlacement.top,
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('一'), findsNothing);
    expect(find.text('狗'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tsit');
    await tester.pumpAndSettle();

    expect(find.text('一'), findsOneWidget);
    expect(find.text('狗'), findsNothing);
    expect(find.byType(EntryListItem), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kau');
    await tester.pumpAndSettle();

    expect(find.text('一'), findsNothing);
    expect(find.text('狗'), findsWidgets);
    expect(find.byType(EntryListItem), findsOneWidget);
  });

  testWidgets('active search with no matches shows only empty state', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDictionaryRepository(
      DictionaryBundle(
        entryCount: 2,
        senseCount: 2,
        exampleCount: 0,
        entries: const [
          DictionaryEntry(
            id: 1,
            type: '',
            hanji: '一',
            romanization: 'tsit',
            category: '',
            audioId: '',
            hokkienSearch: '一 tsit',
            mandarinSearch: '數字 一',
            senses: [
              DictionarySense(
                partOfSpeech: '',
                definition: '數字一',
                examples: [],
              ),
            ],
          ),
          DictionaryEntry(
            id: 2,
            type: '',
            hanji: '狗',
            romanization: 'kau',
            category: '',
            audioId: '',
            hokkienSearch: '狗 kau',
            mandarinSearch: '動物 狗',
            senses: [
              DictionarySense(
                partOfSpeech: '',
                definition: '狗',
                examples: [],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DictionaryScreen(
            repository: repository,
            audioLibrary: OfflineAudioLibrary(),
            searchBarPlacement: SearchBarPlacement.top,
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz-not-found');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('找不到符合的詞條'), findsOneWidget);
    expect(find.byType(EntryListItem), findsNothing);
    expect(find.text('一'), findsNothing);
    expect(find.text('狗'), findsNothing);
  });

  testWidgets('renders flat dictionary flow with no default entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dictionary'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('台語辭典'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.enterText(find.byType(TextField), 'tsit');
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final resultChevron = find.byIcon(Icons.chevron_right).first;
    await tester.ensureVisible(resultChevron);
    await tester.pumpAndSettle();
    await tester.tap(resultChevron);
    await tester.pumpAndSettle();

    expect(find.textContaining('顯示台語詞目對應的華語義項'), findsOneWidget);
  });

  testWidgets('renders settings tab section', (WidgetTester tester) async {
    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Audio Resource Management'), findsOneWidget);
    expect(find.text('Search Bar Position'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Bottom'), findsOneWidget);
  });
}

class _FakeDictionaryRepository extends DictionaryRepository {
  _FakeDictionaryRepository(this.bundle);

  final DictionaryBundle bundle;

  @override
  Future<DictionaryBundle> loadBundle() async {
    return bundle;
  }

  @override
  List<DictionaryEntry> search(
    DictionaryBundle bundle,
    SearchDirection direction,
    String rawQuery,
  ) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const <DictionaryEntry>[];
    }

    return bundle.entries.where((entry) {
      final hokkienMatch =
          normalizeQuery(entry.hanji).contains(query) ||
          normalizeQuery(entry.romanization).contains(query);
      final mandarinMatch = entry.senses.any(
        (sense) => normalizeQuery(sense.definition).contains(query),
      );
      return direction == SearchDirection.hokkienToMandarin
          ? hokkienMatch || mandarinMatch
          : mandarinMatch || hokkienMatch;
    }).toList(growable: false);
  }
}
