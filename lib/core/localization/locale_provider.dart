import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taigi_dict/core/core.dart';

class LocaleProvider extends ChangeNotifier {
  static const _localeKey = 'interface_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _locale = AppLocalizations.localeFromStorage(
      preferences.getString(_localeKey),
    );
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final nextLocale = AppLocalizations.resolveLocale(locale);
    if (_locale == nextLocale) {
      return;
    }

    _locale = nextLocale;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _localeKey,
      AppLocalizations.localeStorageValue(nextLocale),
    );
  }

  Future<void> clearLocalePreference() async {
    if (_locale == null) {
      return;
    }

    _locale = null;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localeKey);
  }
}

class LocaleProviderScope extends InheritedNotifier<LocaleProvider> {
  const LocaleProviderScope({
    super.key,
    required LocaleProvider notifier,
    required super.child,
  }) : super(notifier: notifier);

  static LocaleProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleProviderScope>();
    assert(
      scope != null,
      'LocaleProviderScope is missing from the widget tree.',
    );
    return scope!.notifier!;
  }
}
