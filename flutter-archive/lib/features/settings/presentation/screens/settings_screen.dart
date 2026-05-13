import 'dart:async';
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
  static const double _tabletBreakpoint = 960;
  static const double _tabletMaxContentWidth = 1360;

  @override
  bool get wantKeepAlive => true;

  void _showReferenceArticle(
    BuildContext context, {
    required LocalizedReferenceArticle article,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
    const bottomBodyInset = 24.0;

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
        final offlineResourcesSection = SettingsSectionCard(
          title: l10n.offlineResources,
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
        );
        final appearanceSection = SettingsSectionCard(
          title: l10n.appearance,
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
        );
        final aboutSection = SettingsSectionCard(
          title: l10n.about,
          children: [
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: Text(l10n.advancedSettings),
              subtitle: Text(l10n.advancedSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdvancedSettingsScreen(
                      audioLibrary: widget.audioLibrary,
                      dictionaryLibrary: widget.dictionaryLibrary,
                      onDownloadArchive: widget.onDownloadArchive,
                      onDownloadDictionarySource:
                          widget.onDownloadDictionarySource,
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
              subtitle: Text(l10n.aboutAppSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AboutAppScreen(),
                  ),
                );
              },
            ),
          ],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final useTabletLayout = constraints.maxWidth >= _tabletBreakpoint;

            if (!useTabletLayout) {
              return ListView(
                key: const ValueKey('settings-list'),
                padding: EdgeInsets.only(bottom: bottomBodyInset),
                children: [
                  offlineResourcesSection,
                  appearanceSection,
                  aboutSection,
                ],
              );
            }

            return SingleChildScrollView(
              key: const ValueKey('settings-tablet-layout'),
              padding: EdgeInsets.only(bottom: bottomBodyInset),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _tabletMaxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              offlineResourcesSection,
                              appearanceSection,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [aboutSection],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!widget.showOwnScaffold) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: content,
    );
  }
}
