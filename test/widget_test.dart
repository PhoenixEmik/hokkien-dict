import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hokkien_dictionary/main.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

void main() {
  test('dictionary repository filters and ranks by headword only', () {
    const bundle = DictionaryBundle(
      entryCount: 5,
      senseCount: 5,
      exampleCount: 0,
      entries: [
        DictionaryEntry(
          id: 1,
          type: '',
          hanji: '人民',
          romanization: 'jin-bin',
          category: '',
          audioId: '',
          hokkienSearch: '人民 jin-bin',
          mandarinSearch: '人民',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '人民', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 2,
          type: '',
          hanji: '人民族',
          romanization: 'jin-bin-tso̍k',
          category: '',
          audioId: '',
          hokkienSearch: '人民族 jin-bin-tso̍k',
          mandarinSearch: '民族',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '民族', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 3,
          type: '',
          hanji: '新人民',
          romanization: 'sin-jin-bin',
          category: '',
          audioId: '',
          hokkienSearch: '新人民 sin-jin-bin',
          mandarinSearch: '新人民',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '新人民', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 4,
          type: '',
          hanji: '政權',
          romanization: 'tsing-khuan',
          category: '',
          audioId: '',
          hokkienSearch: '政權 tsing-khuan',
          mandarinSearch: '政權',
          senses: [
            DictionarySense(
              partOfSpeech: '',
              definition: '人民群眾的權力',
              examples: [],
            ),
          ],
        ),
        DictionaryEntry(
          id: 5,
          type: '',
          hanji: '國民',
          romanization: 'kok-bin',
          category: '',
          audioId: '',
          hokkienSearch: '國民 kok-bin',
          mandarinSearch: '國民',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '人民', examples: []),
          ],
        ),
      ],
    );

    final repository = DictionaryRepository();

    final results = repository.search(bundle, '人民');

    expect(results.map((entry) => entry.hanji).toList(), ['人民', '人民族', '新人民']);
    expect(results.any((entry) => entry.hanji == '政權'), isFalse);
    expect(results.any((entry) => entry.hanji == '國民'), isFalse);
    expect(repository.search(bundle, '人人人'), isEmpty);
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
              DictionarySense(partOfSpeech: '', definition: '狗', examples: []),
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
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('一'), findsNothing);
    expect(find.text('狗'), findsNothing);

    await tester.enterText(find.byType(TextField), '一');
    await tester.pumpAndSettle();

    expect(find.text('一'), findsWidgets);
    expect(find.text('狗'), findsNothing);
    expect(find.byType(EntryListItem), findsOneWidget);

    await tester.enterText(find.byType(TextField), '狗');
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
              DictionarySense(partOfSpeech: '', definition: '狗', examples: []),
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
    expect(find.text('開始搜尋'), findsOneWidget);
    expect(find.text('詞目'), findsNothing);
    expect(find.text('義項'), findsNothing);
    expect(find.text('例句'), findsNothing);
    expect(find.text('台語 → 華語'), findsNothing);
    expect(find.text('華語 → 台語'), findsNothing);

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

    expect(find.textContaining('顯示符合查詢的台語詞目與華語義項'), findsOneWidget);
  });

  testWidgets('renders settings tab section', (WidgetTester tester) async {
    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('離線資源'), findsOneWidget);
    expect(find.text('Search Bar Position'), findsNothing);
    expect(find.text('Top'), findsNothing);
    expect(find.text('Bottom'), findsNothing);
    expect(find.text('關於'), findsWidgets);
    expect(find.text('開源授權'), findsOneWidget);

    await tester.ensureVisible(find.text('關於').last);
    await tester.tap(find.text('關於').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('關於台語辭典'), findsOneWidget);
    expect(find.textContaining('App code: MIT'), findsOneWidget);

    await tester.tap(find.text('關閉'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(find.text('開源授權'));
    await tester.tap(find.text('開源授權'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('開源授權'), findsWidgets);
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('套件授權'), findsOneWidget);
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
  List<DictionaryEntry> search(DictionaryBundle bundle, String rawQuery) {
    final query = normalizeQuery(rawQuery);
    if (query.isEmpty) {
      return const <DictionaryEntry>[];
    }

    final matched = bundle.entries
        .where((entry) {
          final headword = normalizeQuery(
            entry.hanji.isNotEmpty ? entry.hanji : entry.romanization,
          );
          return headword.contains(query);
        })
        .toList(growable: false);

    matched.sort((left, right) {
      final leftHeadword = normalizeQuery(
        left.hanji.isNotEmpty ? left.hanji : left.romanization,
      );
      final rightHeadword = normalizeQuery(
        right.hanji.isNotEmpty ? right.hanji : right.romanization,
      );
      final leftPriority = _matchPriority(leftHeadword, query);
      final rightPriority = _matchPriority(rightHeadword, query);
      final comparePriority = leftPriority.compareTo(rightPriority);
      if (comparePriority != 0) {
        return comparePriority;
      }
      return left.id.compareTo(right.id);
    });

    return matched;
  }

  int _matchPriority(String headword, String query) {
    if (headword == query) {
      return 0;
    }
    if (headword.startsWith(query)) {
      return 1;
    }
    return 2;
  }
}
