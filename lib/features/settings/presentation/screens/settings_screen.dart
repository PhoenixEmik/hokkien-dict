import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/core/localization/locale_provider.dart';
import 'package:taigi_dict/core/preferences/app_preferences.dart';
import 'package:taigi_dict/features/dictionary/data/offline_dictionary_library.dart';
import 'package:taigi_dict/features/settings/presentation/content/reference_articles.dart';
import 'package:taigi_dict/features/settings/presentation/screens/advanced_settings_screen.dart';
import 'package:taigi_dict/features/settings/presentation/screens/reference_article_screen.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/audio_resource_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/dictionary_source_resource_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_locale_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_text_scale_tile.dart';
import 'package:taigi_dict/offline_audio.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.dictionaryLibrary,
    required this.onDownloadArchive,
    required this.onDownloadDictionarySource,
    required this.onRebuildDictionaryDatabase,
    this.showOwnScaffold = true,
  });

  final OfflineAudioLibrary audioLibrary;
  final OfflineDictionaryLibrary dictionaryLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;
  final Future<void> Function() onDownloadDictionarySource;
  final Future<void> Function() onRebuildDictionaryDatabase;
  final bool showOwnScaffold;

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
          AdaptiveListTile(
            leading: const Icon(Icons.tune_outlined),
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
          AdaptiveListTile(
            leading: const Icon(Icons.translate_outlined),
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
          AdaptiveListTile(
            leading: const Icon(Icons.edit_note_outlined),
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
          AdaptiveListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: l10n.appTitle,
                applicationLegalese: l10n.aboutLegalese,
                applicationIcon: SvgPicture.asset(
                  'assets/icon/taigi_dict.svg',
                  width: 56,
                  height: 56,
                ),
                children: [
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
              );
            },
          ),
        ];

        final content = LiquidGlassBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      applePlatform ? 12 : 8,
                      16,
                      applePlatform ? 140 : 28,
                    ),
                    children: [
                      AdaptiveFormSection.insetGrouped(
                        header: Text(l10n.offlineResources),
                        children: offlineSection,
                      ),
                      AdaptiveFormSection.insetGrouped(
                        header: Text(l10n.appearance),
                        children: appearanceSection,
                      ),
                      AdaptiveFormSection.insetGrouped(
                        header: Text(l10n.about),
                        children: aboutSection,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        if (!showOwnScaffold) {
          return content;
        }

        return AdaptiveScaffold(
          appBar: AdaptiveAppBar(
            title: l10n.settingsTitle,
            useNativeToolbar: true,
          ),
          body: content,
        );
      },
    );
  }
}

