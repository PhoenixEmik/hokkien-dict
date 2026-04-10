import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/app/shell/main_shell.dart';
import 'package:taigi_dict/app/theme/app_theme.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/localization/locale_provider.dart';
import 'package:taigi_dict/core/preferences/app_preferences.dart';
import 'package:taigi_dict/core/translation/chinese_translation_service.dart';

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
            final applePlatform =
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS);
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              locale: _localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeListResolutionCallback: AppLocalizations.resolveLocaleList,
              theme: buildLightAppTheme(applePlatform: applePlatform),
              darkTheme: _appPreferences.useAmoledTheme
                  ? buildAmoledAppTheme(applePlatform: applePlatform)
                  : buildDarkAppTheme(applePlatform: applePlatform),
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
