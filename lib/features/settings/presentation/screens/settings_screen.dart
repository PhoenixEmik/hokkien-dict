import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/preferences/app_preferences.dart';
import '../../../../offline_audio.dart';
import '../widgets/audio_resource_tile.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_text_scale_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.onDownloadArchive,
  });

  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;

  @override
  Widget build(BuildContext context) {
    final appPreferences = AppPreferencesScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([audioLibrary, appPreferences]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('設定')),
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
                        const SettingsSectionHeader(title: '離線資源'),
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
                        const Divider(height: 32),
                        const SettingsSectionHeader(title: '閱讀文字'),
                        SettingsTextScaleTile(
                          value: appPreferences.readingTextScale,
                          onChanged: (value) {
                            unawaited(
                              appPreferences.setReadingTextScale(value),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        const SettingsSectionHeader(title: '關於'),
                        AboutListTile(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF17454C),
                          ),
                          applicationName: '台語辭典',
                          applicationLegalese:
                              'App code: MIT\nDictionary data and audio: 教育部《臺灣台語常用詞辭典》衍生內容，採 CC BY-NC-ND 2.5 TW。',
                          aboutBoxChildren: const [
                            SizedBox(height: 12),
                            Text('台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。'),
                            SizedBox(height: 12),
                            Text(
                              '參考頁面：https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
                            ),
                          ],
                          applicationIcon: const Icon(
                            Icons.menu_book_outlined,
                            color: Color(0xFF17454C),
                          ),
                          child: const Text('關於台語辭典'),
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
