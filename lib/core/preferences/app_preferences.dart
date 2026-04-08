import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static const _readingTextScaleKey = 'reading_text_scale';
  static const minReadingTextScale = 0.9;
  static const maxReadingTextScale = 1.4;

  double _readingTextScale = 1.0;

  double get readingTextScale => _readingTextScale;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedScale = preferences.getDouble(_readingTextScaleKey);
    if (storedScale == null) {
      return;
    }
    _readingTextScale = storedScale
        .clamp(minReadingTextScale, maxReadingTextScale)
        .toDouble();
    notifyListeners();
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
