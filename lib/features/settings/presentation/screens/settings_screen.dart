import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/localization/locale_provider.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';
import 'package:hokkien_dictionary/features/settings/presentation/content/reference_articles.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/advanced_settings_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/reference_article_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/audio_resource_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/dictionary_source_resource_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_locale_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_text_scale_tile.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.dictionaryLibrary,
    required this.onDownloadArchive,
    required this.onDownloadDictionarySource,
    required this.onRebuildDictionaryDatabase,
  });

  final OfflineAudioLibrary audioLibrary;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;
  final Future<void> Function() onDownloadDictionarySource;
  final Future<void> Function() onRebuildDictionaryDatabase;

  void _showReferenceArticle(
    BuildContext context, {
    required LocalizedReferenceArticle article,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReferenceArticleScreen(
          title: article.title,
          introduction: article.introduction,
          sections: article.sections,
          sourceUrl: article.sourceUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appPreferences = AppPreferencesScope.of(context);
    final localeProvider = LocaleProviderScope.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedLocale =
        localeProvider.locale ??
        AppLocalizations.resolveLocale(Localizations.localeOf(context));

    return AnimatedBuilder(
      animation: Listenable.merge([
        audioLibrary,
        dictionaryLibrary,
        appPreferences,
        localeProvider,
      ]),
      builder: (context, child) {
        final applePlatform = isApplePlatform(context);
        final offlineSection = [
          DictionarySourceResourceTile(
            dictionaryLibrary: dictionaryLibrary,
            onDownload: onDownloadDictionarySource,
          ),
          AudioResourceTile(
            type: AudioArchiveType.word,
            audioLibrary: audioLibrary,
            onDownload: onDownloadArchive,
          ),
          AudioResourceTile(
            type: AudioArchiveType.sentence,
            audioLibrary: audioLibrary,
            onDownload: onDownloadArchive,
          ),
        ];
        final appearanceSection = [
          SettingsLocaleTile(
            value: selectedLocale,
            onSelected: (locale) {
              unawaited(localeProvider.setLocale(locale));
            },
          ),
          SettingsThemeModeTile(
            value: appPreferences.themePreference,
            onSelected: (value) {
              unawaited(appPreferences.setThemePreference(value));
            },
          ),
          SettingsTextScaleTile(
            value: appPreferences.readingTextScale,
            onChanged: (value) {
              unawaited(appPreferences.setReadingTextScale(value));
            },
          ),
        ];
        final aboutSection = [
          ListTile(
            leading: Icon(Icons.tune_outlined, color: colorScheme.primary),
            title: Text(l10n.advancedSettings),
            subtitle: Text(l10n.advancedSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => AdvancedSettingsScreen(
                    onRebuildDictionaryDatabase: onRebuildDictionaryDatabase,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.translate_outlined, color: colorScheme.primary),
            title: Text(l10n.tailoGuide),
            subtitle: Text(l10n.tailoGuideSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReferenceArticle(
                context,
                article: buildTailoReferenceArticle(l10n),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_note_outlined, color: colorScheme.primary),
            title: Text(l10n.hanjiGuide),
            subtitle: Text(l10n.hanjiGuideSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReferenceArticle(
                context,
                article: buildHanjiReferenceArticle(l10n),
              );
            },
          ),
          AboutListTile(
            icon: Icon(Icons.info_outline, color: colorScheme.primary),
            applicationName: l10n.appTitle,
            applicationLegalese: l10n.aboutLegalese,
            aboutBoxChildren: [
              const SizedBox(height: 12),
              Text(l10n.aboutDescription),
              const SizedBox(height: 12),
              Text(
                '${l10n.referencePage}: https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.tailoGuide}: https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.hanjiGuide}: https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
              ),
            ],
            applicationIcon: Icon(
              Icons.menu_book_outlined,
              color: colorScheme.primary,
            ),
            child: Text(l10n.aboutApp),
          ),
        ];

        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: LiquidGlassBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                    ),
                    child: ListTileTheme(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: applePlatform ? 20 : 24,
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          applePlatform ? 16 : 8,
                          16,
                          28,
                        ),
                        children: [
                          SettingsSectionHeader(title: l10n.offlineResources),
                          applePlatform
                              ? LiquidGlassSection(children: offlineSection)
                              : Column(children: offlineSection),
                          if (!applePlatform) const Divider(height: 32),
                          SettingsSectionHeader(title: l10n.appearance),
                          applePlatform
                              ? LiquidGlassSection(children: appearanceSection)
                              : Column(children: appearanceSection),
                          if (!applePlatform) const Divider(height: 32),
                          SettingsSectionHeader(title: l10n.about),
                          applePlatform
                              ? LiquidGlassSection(children: aboutSection)
                              : Column(children: aboutSection),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
