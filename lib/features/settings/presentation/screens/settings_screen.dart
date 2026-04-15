import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';
import 'package:taigi_dict/features/settings/settings.dart';

class SettingsScreen extends StatefulWidget {
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
      PlatformInfo.isIOS
          ? CupertinoPageRoute<void>(
              builder: (_) => ReferenceArticleScreen(
                title: article.title,
                introduction: article.introduction,
                sections: article.sections,
                sourceUrl: article.sourceUrl,
              ),
            )
          : MaterialPageRoute<void>(
              builder: (_) => ReferenceArticleScreen(
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
    super.build(context);
    final appPreferences = AppPreferencesScope.of(context);
    final localeProvider = LocaleProviderScope.of(context);
    final l10n = AppLocalizations.of(context);
    final topBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).top + kToolbarHeight
        : 0.0;
    final bottomBodyInset = PlatformInfo.isIOS
        ? MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 24
        : 24.0;

    final content = AnimatedBuilder(
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
          padding: EdgeInsets.only(bottom: bottomBodyInset),
          children: [
            AdaptiveFormSection.insetGrouped(
              header: Text(l10n.offlineResources),
              children: [
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
              ],
            ),
            AdaptiveFormSection.insetGrouped(
              header: Text(l10n.appearance),
              children: [
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
              ],
            ),
            AdaptiveFormSection.insetGrouped(
              header: Text(l10n.about),
              children: [
                AdaptiveListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: Text(l10n.advancedSettings),
                  subtitle: Text(l10n.advancedSettingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      PlatformInfo.isIOS
                          ? CupertinoPageRoute<void>(
                              builder: (_) => AdvancedSettingsScreen(
                                onRebuildDictionaryDatabase:
                                    widget.onRebuildDictionaryDatabase,
                              ),
                            )
                          : MaterialPageRoute<void>(
                              builder: (_) => AdvancedSettingsScreen(
                                onRebuildDictionaryDatabase:
                                    widget.onRebuildDictionaryDatabase,
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      PlatformInfo.isIOS
                          ? CupertinoPageRoute<void>(
                              builder: (_) => const AboutAppScreen(),
                            )
                          : MaterialPageRoute<void>(
                              builder: (_) => const AboutAppScreen(),
                            ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!widget.showOwnScaffold) {
      return content;
    }

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(title: '設定', useNativeToolbar: true),
      extendBodyBehindAppBar: false,
      useHeroBackButton: false,
      body: Padding(
        padding: EdgeInsets.only(top: topBodyInset),
        child: content,
      ),
    );
  }
}
