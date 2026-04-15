import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taigi_dict/core/core.dart';

void main() {
  group('AppLocalizations locale helpers', () {
    test('resolveLocale maps Chinese variants and unknown locales', () {
      expect(
        AppLocalizations.resolveLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        AppLocalizations.traditionalChineseLocale,
      );
      expect(
        AppLocalizations.resolveLocale(const Locale('zh', 'SG')),
        AppLocalizations.simplifiedChineseLocale,
      );
      expect(
        AppLocalizations.resolveLocale(const Locale('fr', 'FR')),
        AppLocalizations.englishLocale,
      );
    });

    test('locale storage conversion accepts only supported app locales', () {
      expect(
        AppLocalizations.localeStorageValue(const Locale('zh', 'SG')),
        'zh-CN',
      );
      expect(
        AppLocalizations.localeFromStorage('zh-TW'),
        AppLocalizations.traditionalChineseLocale,
      );
      expect(AppLocalizations.localeFromStorage('fr-FR'), isNull);
    });
  });

  group('AppLocalizations label helpers', () {
    test('return current Traditional Chinese strings', () {
      const l10n = AppLocalizations(AppLocalizations.traditionalChineseLocale);

      expect(l10n.readingTextScaleLabel(0.9), '較小');
      expect(l10n.readingTextScaleLabel(1.0), '標準');
      expect(l10n.readingTextScaleLabel(1.2), '較大');
      expect(l10n.readingTextScaleLabel(1.4), '特大');
      expect(l10n.localeLabel(const Locale('zh', 'CN')), '简体中文');
      expect(l10n.audioArchiveLabel(true), '詞目音檔');
      expect(l10n.downloadApproximateSize('1.0 MB'), '大小約 1.0 MB');
    });
  });
}
