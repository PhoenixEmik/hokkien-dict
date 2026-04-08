import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hokkien_dictionary/main.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

void main() {
  final searchField = find.byType(EditableText);
  const searchDebounce = Duration(milliseconds: 350);
  const searchAsyncWait = Duration(seconds: 1);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DictionaryRepository.useBackgroundSearchIsolate = false;
  });

  test(
    'dictionary repository prioritizes headword matches over definitions',
    () {
      const bundle = DictionaryBundle(
        entryCount: 6,
        senseCount: 6,
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
              DictionarySense(
                partOfSpeech: '',
                definition: '新人民',
                examples: [],
              ),
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
          DictionaryEntry(
            id: 6,
            type: '',
            hanji: '洗身軀',
            romanization: 'se sin-khu',
            category: '',
            audioId: '',
            hokkienSearch: '洗身軀 se sin-khu',
            mandarinSearch: '洗澡',
            senses: [
              DictionarySense(partOfSpeech: '', definition: '洗澡', examples: []),
            ],
          ),
        ],
      );

      final repository = DictionaryRepository();

      final results = repository.search(bundle, '人民');

      expect(results.map((entry) => entry.hanji).toList(), [
        '人民',
        '人民族',
        '新人民',
        '國民',
        '政權',
      ]);
      expect(repository.search(bundle, '人人人'), isEmpty);
      expect(
        repository.search(bundle, '洗澡').map((entry) => entry.hanji).toList(),
        ['洗身軀'],
      );
    },
  );

  test('dictionary repository matches romanization without tones', () {
    const bundle = DictionaryBundle(
      entryCount: 4,
      senseCount: 4,
      exampleCount: 0,
      entries: [
        DictionaryEntry(
          id: 1,
          type: '',
          hanji: '一',
          romanization: 'tsi̍t',
          category: '',
          audioId: '',
          hokkienSearch: '一 tsi̍t',
          mandarinSearch: '數字 一',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '數字一。', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 2,
          type: '',
          hanji: '一項',
          romanization: 'tsit-hāng',
          category: '',
          audioId: '',
          hokkienSearch: '一項 tsit-hāng',
          mandarinSearch: '一項',
          senses: [
            DictionarySense(
              partOfSpeech: '',
              definition: '一個項目。',
              examples: [],
            ),
          ],
        ),
        DictionaryEntry(
          id: 3,
          type: '',
          hanji: '七一',
          romanization: 'chhit-tsit8',
          category: '',
          audioId: '',
          hokkienSearch: '七一 chhit-tsit8',
          mandarinSearch: '七一',
          senses: [
            DictionarySense(
              partOfSpeech: '',
              definition: '包含 tsit 音節。',
              examples: [],
            ),
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
            DictionarySense(partOfSpeech: '', definition: '不相關。', examples: []),
          ],
        ),
      ],
    );

    final repository = DictionaryRepository();

    expect(removeTones('Tsìt4 tsi̍t8'), 'tsit tsit');

    final results = repository.search(bundle, 'tsit');

    expect(results.map((entry) => entry.hanji).toList(), ['一', '一項', '七一']);
    expect(results.any((entry) => entry.hanji == '政權'), isFalse);
  });

  test('app preferences stores reading text scale', () async {
    final preferences = AppPreferences();
    await preferences.initialize();

    expect(preferences.readingTextScale, 1.0);

    await preferences.setReadingTextScale(1.3);

    final restoredPreferences = AppPreferences();
    await restoredPreferences.initialize();

    expect(restoredPreferences.readingTextScale, 1.3);
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
            bookmarkStore: BookmarkStore(),
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('一'), findsNothing);
    expect(find.text('狗'), findsNothing);

    await tester.enterText(searchField, '一');
    await tester.pump(searchDebounce);
    await tester.pump(searchAsyncWait);

    expect(find.text('一'), findsWidgets);
    expect(find.text('狗'), findsNothing);
    expect(find.byType(EntryListItem), findsOneWidget);

    await tester.enterText(searchField, '狗');
    await tester.pump(searchDebounce);
    await tester.pump(searchAsyncWait);

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
            bookmarkStore: BookmarkStore(),
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'zzzz-not-found');
    await tester.pump(searchDebounce);
    await tester.pump(searchAsyncWait);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));

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
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('開始搜尋'), findsOneWidget);
    expect(find.text('詞目'), findsNothing);
    expect(find.text('義項'), findsNothing);
    expect(find.text('例句'), findsNothing);
    expect(find.text('台語 → 華語'), findsNothing);
    expect(find.text('華語 → 台語'), findsNothing);

    expect(find.byType(SearchBar), findsOneWidget);

    await tester.enterText(searchField, 'tsit');
    await tester.pump(searchDebounce);
    await tester.pump(searchAsyncWait);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EntryListItem), findsWidgets);
  });

  testWidgets('renders settings tab section', (WidgetTester tester) async {
    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('離線資源'), findsOneWidget);
    expect(find.text('閱讀文字'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Search Bar Position'), findsNothing);
    expect(find.text('Top'), findsNothing);
    expect(find.text('Bottom'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('關於台語辭典'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('關於'), findsOneWidget);
    expect(find.text('關於台語辭典'), findsOneWidget);
    expect(find.text('開源授權'), findsNothing);

    await tester.tap(find.text('關於台語辭典'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('台語辭典'), findsOneWidget);
    expect(find.text('台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。'), findsOneWidget);
    expect(find.textContaining('CC BY-NC-ND 2.5 TW'), findsOneWidget);
    expect(find.textContaining('App code: MIT'), findsOneWidget);
    expect(find.textContaining('sutian.moe.edu.tw'), findsOneWidget);
  });

  testWidgets('shows, applies, and clears search history', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'recent_search_history': <String>['狗', '一'],
    });

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
            bookmarkStore: BookmarkStore(),
            onActionResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('搜尋紀錄'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '狗'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '一'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, '狗'));
    await tester.pump(searchAsyncWait);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(EntryListItem), findsOneWidget);
    expect(find.text('搜尋紀錄'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(searchAsyncWait);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('搜尋紀錄'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('搜尋紀錄'), findsNothing);
    expect(find.widgetWithText(ActionChip, '狗'), findsNothing);
  });

  testWidgets('bookmarks screen updates after toggling a saved word', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDictionaryRepository(
      DictionaryBundle(
        entryCount: 1,
        senseCount: 1,
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
                definition: '數字一。',
                examples: [],
              ),
            ],
          ),
        ],
      ),
    );
    final bookmarkStore = BookmarkStore();
    await bookmarkStore.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: BookmarksScreen(
          repository: repository,
          audioLibrary: OfflineAudioLibrary(),
          bookmarkStore: bookmarkStore,
          onActionResult: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('尚未加入任何書籤'), findsOneWidget);

    await bookmarkStore.toggleBookmark(1);
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();

    expect(find.text('書籤'), findsOneWidget);
    expect(find.text('一'), findsOneWidget);
  });
}

class _FakeDictionaryRepository extends DictionaryRepository {
  _FakeDictionaryRepository(this.bundle);

  final DictionaryBundle bundle;

  @override
  Future<DictionaryBundle> loadBundle() async {
    return bundle;
  }
}
