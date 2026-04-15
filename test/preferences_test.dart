import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taigi_dict/core/core.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppThemePreference', () {
    test('parses storage values and exposes theme modes', () {
      expect(
        AppThemePreferenceX.fromStorageValue('amoled'),
        AppThemePreference.amoled,
      );
      expect(
        AppThemePreferenceX.fromStorageValue('bad-value'),
        AppThemePreference.system,
      );
      expect(AppThemePreference.amoled.storageValue, 'amoled');
      expect(AppThemePreference.amoled.materialThemeMode, ThemeMode.dark);
    });
  });

  group('AppPreferences', () {
    test('clamps and snaps reading text scale changes', () async {
      final preferences = AppPreferences();
      await preferences.initialize();

      await preferences.setReadingTextScale(0.2);
      expect(preferences.readingTextScale, AppPreferences.minReadingTextScale);

      await preferences.setReadingTextScale(1.16);
      expect(preferences.readingTextScale, 1.2);

      await preferences.setReadingTextScale(9);
      expect(preferences.readingTextScale, AppPreferences.maxReadingTextScale);
    });
  });

  group('LocaleProvider', () {
    test('clears stored locale preferences', () async {
      SharedPreferences.setMockInitialValues({'interface_locale': 'zh-CN'});

      final provider = LocaleProvider();
      await provider.initialize();
      expect(provider.locale, AppLocalizations.simplifiedChineseLocale);

      await provider.clearLocalePreference();

      final preferences = await SharedPreferences.getInstance();
      expect(provider.locale, isNull);
      expect(preferences.getString('interface_locale'), isNull);
    });
  });
}
