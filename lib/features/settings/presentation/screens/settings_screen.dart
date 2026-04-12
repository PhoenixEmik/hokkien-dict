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
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_locale_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/settings_text_scale_tile.dart';
import 'package:taigi_dict/offline_audio.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

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

  glass.LiquidGlassSettings _sectionSettings(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return glass.LiquidGlassSettings(
      blur: 28,
      thickness: 34,
      glassColor: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.12),
      lightIntensity: brightness == Brightness.dark ? 0.44 : 0.62,
      ambientStrength: brightness == Brightness.dark ? 0.08 : 0.03,
      refractiveIndex: 1.16,
      saturation: brightness == Brightness.dark ? 1.2 : 1.06,
      chromaticAberration: 0.008,
      specularSharpness: glass.GlassSpecularSharpness.medium,
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
            applicationIcon: SvgPicture.asset(
              'assets/icon/taigi_dict.svg',
              width: 56,
              height: 56,
            ),
            child: Text(l10n.aboutApp),
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
                  child: ListTileTheme(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: applePlatform ? 20 : 24,
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        applePlatform ? 12 : 8,
                        16,
                        applePlatform ? 140 : 28,
                      ),
                      children: [
                        SettingsSectionHeader(title: l10n.offlineResources),
                        applePlatform
                            ? _GlassSettingsGroup(
                                settings: _sectionSettings(context),
                                children: offlineSection,
                              )
                            : Column(children: offlineSection),
                        if (!applePlatform) const Divider(height: 32),
                        SettingsSectionHeader(title: l10n.appearance),
                        applePlatform
                            ? _GlassSettingsGroup(
                                settings: _sectionSettings(context),
                                children: appearanceSection,
                              )
                            : Column(children: appearanceSection),
                        if (!applePlatform) const Divider(height: 32),
                        SettingsSectionHeader(title: l10n.about),
                        applePlatform
                            ? _GlassSettingsGroup(
                                settings: _sectionSettings(context),
                                children: aboutSection,
                              )
                            : Column(children: aboutSection),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );

        if (!showOwnScaffold) {
          return content;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: applePlatform
              ? glass.GlassAppBar(
                  useOwnLayer: true,
                  quality: glass.GlassQuality.premium,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    l10n.settingsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: resolveLiquidGlassForeground(context),
                    ),
                  ),
                )
              : AppBar(title: Text(l10n.settingsTitle)),
          body: content,
        );
      },
    );
  }
}

class _GlassSettingsGroup extends StatelessWidget {
  const _GlassSettingsGroup({required this.settings, required this.children});

  final glass.LiquidGlassSettings settings;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return glass.GlassCard(
      useOwnLayer: true,
      quality: glass.GlassQuality.standard,
      settings: settings,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 4),
      shape: const glass.LiquidRoundedSuperellipse(borderRadius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 72,
                endIndent: 16,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }
}
