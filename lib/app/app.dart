import 'dart:async';

import 'package:flutter/material.dart';

import '../core/preferences/app_preferences.dart';
import 'shell/main_shell.dart';
import 'theme/app_theme.dart';

class HokkienDictionaryApp extends StatefulWidget {
  const HokkienDictionaryApp({super.key});

  @override
  State<HokkienDictionaryApp> createState() => _HokkienDictionaryAppState();
}

class _HokkienDictionaryAppState extends State<HokkienDictionaryApp> {
  final AppPreferences _appPreferences = AppPreferences();

  @override
  void initState() {
    super.initState();
    unawaited(_appPreferences.initialize());
  }

  @override
  void dispose() {
    _appPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPreferencesScope(
      notifier: _appPreferences,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '台語辭典',
        theme: buildAppTheme(),
        home: const MainScreen(),
      ),
    );
  }
}
