import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/core/localization/locale_provider.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';
import 'package:hokkien_dictionary/features/settings/presentation/content/reference_articles.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/reference_article_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/audio_resource_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/dictionary_source_resource_tile.dart';
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

  Future<void> _handleRebuildDictionaryDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(l10n.rebuildingDictionaryDatabase)),
              ],
            ),
          ),
        );
      },
    );

    Object? error;
    try {
      await onRebuildDictionaryDatabase();
    } catch (caught) {
      error = caught;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? l10n.rebuildDictionaryDatabaseSuccess
                : error is MissingDictionarySourceException
                ? l10n.downloadDictionarySourceFirst
                : error is CorruptedDictionarySourceException
                ? l10n.dictionarySourceCorrupted
                : error is MissingDictionarySheetException
                ? l10n.dictionarySourceSheetMissing(error.sheetName)
                : l10n.dictionaryDatabaseRebuildFailed('$error'),
          ),
          backgroundColor: error == null
              ? const Color(0xFF0E2F35)
              : const Color(0xFF8A3B1F),
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
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth >= 900 ? 920 : 720,
                  ),
                  child: ListTileTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                      children: [
                        SettingsSectionHeader(title: l10n.offlineResources),
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
                        ListTile(
                          leading: const Icon(
                            Icons.storage_outlined,
                            color: Color(0xFF17454C),
                          ),
                          title: Text(l10n.rebuildDictionaryDatabase),
                          subtitle: Text(
                            l10n.rebuildDictionaryDatabaseSubtitle,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            unawaited(
                              _handleRebuildDictionaryDatabase(context),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        SettingsSectionHeader(title: l10n.appearance),
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
                            unawaited(
                              appPreferences.setReadingTextScale(value),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        SettingsSectionHeader(title: l10n.about),
                        ListTile(
                          leading: const Icon(
                            Icons.translate_outlined,
                            color: Color(0xFF17454C),
                          ),
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
                          leading: const Icon(
                            Icons.edit_note_outlined,
                            color: Color(0xFF17454C),
                          ),
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
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF17454C),
                          ),
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
                          applicationIcon: const Icon(
                            Icons.menu_book_outlined,
                            color: Color(0xFF17454C),
                          ),
                          child: Text(l10n.aboutApp),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
