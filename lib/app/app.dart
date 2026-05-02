import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taigi_dict/app/app_module.dart';
import 'package:taigi_dict/core/core.dart';


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
    unawaited(ChineseTranslationService.instance.initialize());
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
            final darkTheme = _appPreferences.useAmoledTheme
              ? buildAmoledAppTheme()
              : buildDarkAppTheme();

            return MaterialApp(
              title: '台語辭典',
              onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
              locale: _localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeListResolutionCallback: AppLocalizations.resolveLocaleList,
              themeMode: _appPreferences.materialThemeMode,
              theme: buildLightAppTheme(),
              darkTheme: darkTheme,
              home: child,
            );
          },
          child: const MainScreen(),
        ),
      ),
    );
  }
}
