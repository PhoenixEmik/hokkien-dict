import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/settings/settings.dart';

void main() {
  group('AboutAppScreen l10n', () {
    testWidgets('renders Traditional Chinese labels and project details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: AppLocalizations.traditionalChineseLocale,
          home: const AboutAppScreen(),
        ),
      );

      expect(find.text('關於台語辭典'), findsOneWidget);
      expect(find.text('台語辭典'), findsOneWidget);
      expect(find.text('版本'), findsOneWidget);
      expect(find.text('作者'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('授權資訊'), findsOneWidget);
      expect(find.text(AppConstants.appVersion), findsOneWidget);
      expect(find.text(AppConstants.appAuthor), findsOneWidget);
      expect(find.text(AppConstants.appRepositoryUrl), findsOneWidget);
    });

    testWidgets('renders English labels without Traditional Chinese chrome', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: AppLocalizations.englishLocale,
          home: const AboutAppScreen(),
        ),
      );

      expect(find.text('About Hokkien Dictionary'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Licenses'), findsOneWidget);
      expect(find.text('關於台語辭典'), findsNothing);
      expect(find.text('授權資訊'), findsNothing);
    });
  });

  group('LicenseSummaryScreen l10n', () {
    testWidgets('renders Simplified Chinese license labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: AppLocalizations.simplifiedChineseLocale,
          home: const LicenseSummaryScreen(),
        ),
      );

      expect(find.text('授权资讯'), findsOneWidget);
      expect(find.text('App 程式码'), findsOneWidget);
      expect(find.text('MIT 授权'), findsOneWidget);
      expect(find.text('词典资料'), findsOneWidget);
      expect(find.text('词典音档'), findsOneWidget);
      expect(find.text('Flutter 与套件授权'), findsOneWidget);
      expect(find.textContaining('CC BY-ND 3.0 TW'), findsWidgets);
    });
  });

  group('new settings pages a11y', () {
    testWidgets(
      'about page exposes readable semantics and action rows as buttons',
      (WidgetTester tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _buildLocalizedTestApp(
              locale: AppLocalizations.traditionalChineseLocale,
              home: const AboutAppScreen(),
            ),
          );

          expect(find.bySemanticsLabel(RegExp('台語辭典')), findsWidgets);
          expect(find.bySemanticsLabel(RegExp('版本')), findsWidgets);
          expect(
            find.bySemanticsLabel(
              RegExp(RegExp.escape(AppConstants.appVersion)),
            ),
            findsWidgets,
          );
          expect(find.bySemanticsLabel(RegExp('作者')), findsWidgets);
          expect(
            find.bySemanticsLabel(
              RegExp(RegExp.escape(AppConstants.appAuthor)),
            ),
            findsWidgets,
          );
          expect(
            tester.getSemantics(
              find.bySemanticsLabel('GitHub。${AppConstants.appRepositoryUrl}'),
            ),
            matchesSemantics(
              label: 'GitHub。${AppConstants.appRepositoryUrl}',
              isButton: true,
              hasTapAction: true,
            ),
          );
          expect(
            tester.getSemantics(
              find.bySemanticsLabel('授權資訊。查看 Flutter 彙整的開源套件詳細授權。'),
            ),
            matchesSemantics(
              label: '授權資訊。查看 Flutter 彙整的開源套件詳細授權。',
              isButton: true,
              hasTapAction: true,
            ),
          );
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets('license page exposes Flutter licenses as a button', (
      WidgetTester tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildLocalizedTestApp(
            locale: AppLocalizations.traditionalChineseLocale,
            home: const LicenseSummaryScreen(),
          ),
        );

        expect(find.bySemanticsLabel(RegExp('授權資訊')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('App 程式碼')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('詞典資料')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('詞典音檔')), findsWidgets);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Flutter 與套件授權。查看 Flutter 彙整的開源套件詳細授權。'),
          ),
          matchesSemantics(
            label: 'Flutter 與套件授權。查看 Flutter 彙整的開源套件詳細授權。',
            isButton: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('license navigation reaches Flutter package license details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedTestApp(
          locale: AppLocalizations.traditionalChineseLocale,
          home: const AboutAppScreen(),
        ),
      );

      await tester.tap(find.text('授權資訊'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Flutter 與套件授權'), findsOneWidget);

      await tester.tap(find.text('Flutter 與套件授權'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Powered by Flutter'), findsOneWidget);
    });
  });
}

Widget _buildLocalizedTestApp({required Locale locale, required Widget home}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}
