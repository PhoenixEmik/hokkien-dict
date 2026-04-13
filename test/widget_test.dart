import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/features/dictionary/presentation/widgets/audio_button.dart';
import 'package:taigi_dict/features/dictionary/presentation/widgets/interactive_definition_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taigi_dict/main.dart';
import 'package:taigi_dict/offline_audio.dart';

void main() {
  final searchField = find.byType(EditableText);
  const searchDebounce = Duration(milliseconds: 350);
  const searchAsyncWait = Duration(seconds: 1);
  const traditionalChineseLocale = Locale('zh', 'TW');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DictionaryRepository.useBackgroundSearchIsolate = false;
    DictionaryRepository.preferLocalDatabase = false;
    DictionaryRepository.debugFallbackBundle = _testAppBundle;
    DictionaryRepository.clearBundleCache();
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

  test('dictionary repository resolves linked words by exact headword', () {
    const bundle = DictionaryBundle(
      entryCount: 3,
      senseCount: 3,
      exampleCount: 0,
      entries: [
        DictionaryEntry(
          id: 1,
          type: '',
          hanji: '母',
          romanization: 'bo',
          category: '',
          audioId: '',
          hokkienSearch: '母 bo',
          mandarinSearch: '母親',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '母親。', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 2,
          type: '',
          hanji: '母仔',
          romanization: 'bo-a',
          category: '',
          audioId: '',
          hokkienSearch: '母仔 bo-a',
          mandarinSearch: '雌性',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '雌性的。', examples: []),
          ],
        ),
        DictionaryEntry(
          id: 3,
          type: '',
          hanji: '無',
          romanization: 'bo',
          category: '',
          audioId: '',
          hokkienSearch: '無 bo',
          mandarinSearch: '沒有',
          senses: [
            DictionarySense(partOfSpeech: '', definition: '沒有。', examples: []),
          ],
        ),
      ],
    );

    final repository = DictionaryRepository();

    expect(repository.findLinkedEntry(bundle, '母')?.id, 1);
    expect(repository.findLinkedEntry(bundle, 'bo')?.id, 1);
    expect(repository.findLinkedEntry(bundle, '母仔')?.id, 2);
    expect(repository.findLinkedEntry(bundle, '母親'), isNull);
  });

  test('interactive definition parser marks bracketed words as actionable', () {
    final segments = parseDefinitionSegments('釋義參見【母】bó 條。');

    expect(segments, hasLength(3));
    expect(segments[0].displayText, '釋義參見');
    expect(segments[0].isActionable, isFalse);
    expect(segments[1].displayText, '【母】');
    expect(segments[1].actionWord, '母');
    expect(segments[1].isActionable, isTrue);
    expect(segments[2].displayText, 'bó 條。');
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

  test('app preferences stores theme preference', () async {
    final preferences = AppPreferences();
    await preferences.initialize();

    expect(preferences.themePreference, AppThemePreference.system);

    await preferences.setThemePreference(AppThemePreference.amoled);

    final restoredPreferences = AppPreferences();
    await restoredPreferences.initialize();

    expect(restoredPreferences.themePreference, AppThemePreference.amoled);
    expect(restoredPreferences.materialThemeMode, ThemeMode.dark);
    expect(restoredPreferences.useAmoledTheme, isTrue);
  });

  test('locale provider stores selected locale', () async {
    final provider = LocaleProvider();
    await provider.initialize();

    expect(provider.locale, isNull);

    await provider.setLocale(const Locale('zh', 'CN'));

    final restoredProvider = LocaleProvider();
    await restoredProvider.initialize();

    expect(restoredProvider.locale, const Locale('zh', 'CN'));
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
      _buildLocalizedTestApp(
        locale: traditionalChineseLocale,
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
      _buildLocalizedTestApp(
        locale: traditionalChineseLocale,
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
    SharedPreferences.setMockInitialValues({'interface_locale': 'zh-TW'});

    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('辭典'), findsOneWidget);
    expect(find.text('書籤'), findsOneWidget);
    expect(find.text('設定'), findsWidgets);
    expect(find.text('詞目'), findsNothing);
    expect(find.text('義項'), findsNothing);
    expect(find.text('例句'), findsNothing);
    expect(find.text('台語 → 華語'), findsNothing);
    expect(find.text('華語 → 台語'), findsNothing);

    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'tsit');
    await tester.pump(searchDebounce);
    await tester.pump(searchAsyncWait);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EntryListItem), findsWidgets);
  });

  testWidgets('renders settings tab section', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'interface_locale': 'zh-TW'});

    await tester.pumpWidget(const HokkienDictionaryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('設定'), findsWidgets);
    expect(find.text('離線資源'), findsOneWidget);
    expect(find.text('外觀'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Language / 語言'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Language / 語言'), findsOneWidget);
    expect(find.text('主題'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('字級'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Search Bar Position'), findsNothing);
    expect(find.text('Top'), findsNothing);
    expect(find.text('Bottom'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('臺羅標注說明'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('臺羅標注說明'), findsOneWidget);
    expect(find.text('漢字用字原則'), findsOneWidget);

    await tester.tap(find.text('臺羅標注說明'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('臺羅標注說明'), findsWidgets);
    expect(find.text('拼寫基礎'), findsOneWidget);
    expect(find.textContaining('音節之間會用連字符號標示多音節詞'), findsOneWidget);
    expect(find.text('聲調舉例'), findsOneWidget);
    expect(find.text('tong1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

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
    expect(find.textContaining('CC BY-ND 3.0 TW'), findsOneWidget);
    expect(find.textContaining('App code: MIT'), findsOneWidget);
    expect(
      find.textContaining(
        'https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('tailo-phiautsu-suatbing'), findsOneWidget);
    expect(find.textContaining('hanji-iongji-guantsik'), findsOneWidget);
    expect(find.textContaining('sutian-huliok'), findsNothing);
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
      _buildLocalizedTestApp(
        locale: traditionalChineseLocale,
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
      _buildLocalizedTestApp(
        locale: traditionalChineseLocale,
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

  testWidgets('entry list item exposes a merged semantics label', (
    WidgetTester tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      const entry = DictionaryEntry(
        id: 1,
        type: '',
        hanji: '狗',
        romanization: 'kau',
        category: '',
        audioId: '',
        hokkienSearch: '狗 kau',
        mandarinSearch: '狗',
        senses: [
          DictionarySense(partOfSpeech: '', definition: '狗', examples: []),
        ],
      );

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: traditionalChineseLocale,
          home: Scaffold(
            body: EntryListItem(entry: entry, onTap: () {}),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('狗。白話字 kau。釋義 狗')),
        matchesSemantics(
          label: '狗。白話字 kau。釋義 狗',
          hint: '雙擊開啟詞條詳細資料',
          isButton: true,
        ),
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('alias entry list item points to the primary entry', (
    WidgetTester tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      const entry = DictionaryEntry(
        id: 18343,
        type: '近反義詞不單列詞目者',
        hanji: '男人',
        romanization: 'lâm-jîn',
        category: '',
        audioId: '',
        hokkienSearch: '男人 lam-jin lâm-jîn',
        mandarinSearch: '',
        aliasTargetEntryId: 3347,
        senses: [
          DictionarySense(
            partOfSpeech: '',
            definition: '近反義詞不單列詞目者',
            examples: [],
          ),
        ],
      );

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: traditionalChineseLocale,
          home: Scaffold(
            body: EntryListItem(entry: entry, onTap: () {}),
          ),
        ),
      );

      expect(find.text('→ 查閱主詞條'), findsOneWidget);
      expect(find.text('近反義詞不單列詞目者'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('男人。白話字 lâm-jîn。查閱主詞條')),
        matchesSemantics(
          label: '男人。白話字 lâm-jîn。查閱主詞條',
          hint: '雙擊開啟詞條詳細資料',
          isButton: true,
        ),
      );
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('audio button exposes descriptive semantics', (
    WidgetTester tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: traditionalChineseLocale,
          home: Scaffold(
            body: AudioButton(
              type: AudioArchiveType.word,
              audioId: 'sample-audio',
              audioLibrary: OfflineAudioLibrary(),
              onPressed: (_, _) async {},
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('下載詞目音檔')),
        matchesSemantics(
          label: '下載詞目音檔',
          tooltip: '下載詞目音檔',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    } finally {
      semanticsHandle.dispose();
    }
  });
}

Widget _buildLocalizedTestApp({
  required Widget home,
  Locale locale = const Locale('zh', 'TW'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

class _FakeDictionaryRepository extends DictionaryRepository {
  _FakeDictionaryRepository(this.bundle);

  final DictionaryBundle bundle;

  @override
  Future<DictionaryBundle> loadBundle() async {
    return bundle;
  }
}

const _testAppBundle = DictionaryBundle(
  entryCount: 3,
  senseCount: 3,
  exampleCount: 0,
  entries: [
    DictionaryEntry(
      id: 1,
      type: '',
      hanji: '一',
      romanization: 'tsi̍t',
      category: '',
      audioId: '',
      hokkienSearch: '一 tsit tsi̍t',
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
      hokkienSearch: '一項 tsit-hang tsit-hāng',
      mandarinSearch: '一個項目',
      senses: [
        DictionarySense(partOfSpeech: '', definition: '一個項目。', examples: []),
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
  ],
);
