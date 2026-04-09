import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/app/shell/main_shell.dart';
import 'package:hokkien_dictionary/app/theme/app_theme.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/localization/locale_provider.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';

class HokkienDictionaryApp extends StatefulWidget {
  const HokkienDictionaryApp({super.key});

  @override
  State<HokkienDictionaryApp> createState() => _HokkienDictionaryAppState();
}

class _HokkienDictionaryAppState extends State<HokkienDictionaryApp> {
  final AppPreferences _appPreferences = AppPreferences();
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    unawaited(_appPreferences.initialize());
    unawaited(_localeProvider.initialize());
  }

  @override
  void dispose() {
    _localeProvider.dispose();
    _appPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProviderScope(
      notifier: _localeProvider,
      child: AppPreferencesScope(
        notifier: _appPreferences,
        child: ListenableBuilder(
          listenable: Listenable.merge([_appPreferences, _localeProvider]),
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              locale: _localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeListResolutionCallback: AppLocalizations.resolveLocaleList,
              theme: buildLightAppTheme(),
              darkTheme: _appPreferences.useAmoledTheme
                  ? buildAmoledAppTheme()
                  : buildDarkAppTheme(),
              themeMode: _appPreferences.materialThemeMode,
              home: child,
            );
          },
          child: const MainScreen(),
        ),
      ),
    );
  }
}
