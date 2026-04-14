import 'dart:async';

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
import 'package:taigi_dict/features/settings/presentation/widgets/settings_locale_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_text_scale_tile.dart';
import 'package:taigi_dict/offline_audio.dart';

class SettingsScreen extends StatefulWidget {
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

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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


  Widget _buildSectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final divider = const Divider(height: 1, indent: 56, endIndent: 0);
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) separated.add(divider);
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: separated),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appPreferences = AppPreferencesScope.of(context);
    final localeProvider = LocaleProviderScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.audioLibrary,
          widget.dictionaryLibrary,
          appPreferences,
          localeProvider,
        ]),
        builder: (context, child) {
          final selectedLocale =
              localeProvider.locale ??
              AppLocalizations.resolveLocale(Localizations.localeOf(context));

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildSectionHeader(context, l10n.offlineResources),
              _buildCard([
                DictionarySourceResourceTile(
                  dictionaryLibrary: widget.dictionaryLibrary,
                  onDownload: widget.onDownloadDictionarySource,
                ),
                AudioResourceTile(
                  type: AudioArchiveType.word,
                  audioLibrary: widget.audioLibrary,
                  onDownload: widget.onDownloadArchive,
                ),
                AudioResourceTile(
                  type: AudioArchiveType.sentence,
                  audioLibrary: widget.audioLibrary,
                  onDownload: widget.onDownloadArchive,
                ),
              ]),
              _buildSectionHeader(context, l10n.appearance),
              _buildCard([
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
              ]),
              _buildSectionHeader(context, l10n.about),
              _buildCard([
                ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: Text(l10n.advancedSettings),
                  subtitle: Text(l10n.advancedSettingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => AdvancedSettingsScreen(
                          onRebuildDictionaryDatabase:
                              widget.onRebuildDictionaryDatabase,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
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
                ListTile(
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
                ListTile(
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
              ]),
            ],
          );
        },
      ),
    );
  }
}

