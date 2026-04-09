import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark, amoled }

extension AppThemePreferenceX on AppThemePreference {
  String get storageValue => switch (this) {
    AppThemePreference.system => 'system',
    AppThemePreference.light => 'light',
    AppThemePreference.dark => 'dark',
    AppThemePreference.amoled => 'amoled',
  };

  ThemeMode get materialThemeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
    AppThemePreference.amoled => ThemeMode.dark,
  };

  static AppThemePreference fromStorageValue(String? value) {
    return AppThemePreference.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

class AppPreferences extends ChangeNotifier {
  static const _readingTextScaleKey = 'reading_text_scale';
  static const _themePreferenceKey = 'theme_preference';
  static const minReadingTextScale = 0.9;
  static const maxReadingTextScale = 1.4;

  double _readingTextScale = 1.0;
  AppThemePreference _themePreference = AppThemePreference.system;

  double get readingTextScale => _readingTextScale;
  AppThemePreference get themePreference => _themePreference;
  ThemeMode get materialThemeMode => _themePreference.materialThemeMode;
  bool get useAmoledTheme => _themePreference == AppThemePreference.amoled;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _themePreference = AppThemePreferenceX.fromStorageValue(
      preferences.getString(_themePreferenceKey),
    );
    final storedScale = preferences.getDouble(_readingTextScaleKey);
    if (storedScale != null) {
      _readingTextScale = storedScale
          .clamp(minReadingTextScale, maxReadingTextScale)
          .toDouble();
    }
    notifyListeners();
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    if (_themePreference == value) {
      return;
    }

    _themePreference = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, value.storageValue);
  }

  Future<void> setReadingTextScale(double value) async {
    final nextValue = value
        .clamp(minReadingTextScale, maxReadingTextScale)
        .toDouble();
    if (_readingTextScale == nextValue) {
      return;
    }

    _readingTextScale = nextValue;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_readingTextScaleKey, nextValue);
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferences> {
  const AppPreferencesScope({
    super.key,
    required AppPreferences notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppPreferences of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(
      scope != null,
      'AppPreferencesScope is missing from the widget tree.',
    );
    return scope!.notifier!;
  }
}
