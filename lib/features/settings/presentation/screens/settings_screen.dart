import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/preferences/app_preferences.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/reference_article_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/audio_resource_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/settings_text_scale_tile.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.audioLibrary,
    required this.onDownloadArchive,
  });

  final OfflineAudioLibrary audioLibrary;
  final Future<void> Function(AudioArchiveType type) onDownloadArchive;

  void _showReferenceArticle(
    BuildContext context, {
    required String title,
    required String introduction,
    required List<ReferenceArticleSection> sections,
    required String sourceUrl,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReferenceArticleScreen(
          title: title,
          introduction: introduction,
          sections: sections,
          sourceUrl: sourceUrl,
        ),
      ),
    );
  }

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
                        const SettingsSectionHeader(title: '外觀'),
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
                        const SettingsSectionHeader(title: '關於'),
                        ListTile(
                          leading: const Icon(
                            Icons.translate_outlined,
                            color: Color(0xFF17454C),
                          ),
                          title: const Text('臺羅標注說明'),
                          subtitle: const Text('查看教育部頁面的重點整理與台羅拼寫原則。'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showReferenceArticle(
                              context,
                              title: '臺羅標注說明',
                              introduction:
                                  '這份頁面整理了教育部臺灣台語常用詞辭典採用的臺羅拼寫方式。重點在於讓讀者理解聲母、韻母、鼻化、入聲與聲調標記的組合方式，並用一致的書寫規則處理詞目與例句。',
                              sections: const [
                                ReferenceArticleSection(
                                  title: '拼寫基礎',
                                  paragraphs: [
                                    '頁面先交代辭典以臺灣閩南語羅馬字拼音方案為基礎，詞目與例句都盡量依同一套拼寫系統呈現，方便查詢、檢索與交叉參照。',
                                  ],
                                  bullets: [
                                    '聲母與韻母會依標準臺羅拆分，讓使用者可以對照讀音結構。',
                                    '鼻化、喉塞與入聲字尾會保留在拼寫中，不另外改寫成口語化的簡略形式。',
                                    '音節之間會用連字符號標示多音節詞，讓詞形邊界更清楚。',
                                  ],
                                ),
                                ReferenceArticleSection(
                                  title: '聲調標示',
                                  paragraphs: [
                                    '辭典中的調號寫法以臺羅慣用的數字與附加符號系統為準，目的不是追求各地方腔的完全細分，而是提供穩定、可查找的標記方法。',
                                  ],
                                  bullets: [
                                    '一般音節以調符呈現主要聲調差異。',
                                    '入聲與變調相關情況會依辭典編排需要保留可辨識的形式。',
                                    '若同一詞條存在常見異讀，辭典會依編輯原則選定主要寫法，再視需要補充其他資訊。',
                                  ],
                                ),
                                ReferenceArticleSection(
                                  title: '查詢時怎麼用',
                                  paragraphs: [
                                    '實際使用時，可以先把臺羅當成穩定的索引工具。即使不熟悉全部符號，也能先用基本拼法輸入，再回頭比對詞條內的正式標注。',
                                  ],
                                  bullets: [
                                    '先抓聲母與韻母的大致形狀，再確認聲調。',
                                    '遇到鼻化或連字符時，不必把它們當成裝飾；它們本身就是辨識詞義的重要線索。',
                                    '如果查詢結果接近但不完全相同，優先比對詞條裡的正式臺羅標注與例句讀音。',
                                  ],
                                ),
                              ],
                              sourceUrl:
                                  'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.edit_note_outlined,
                            color: Color(0xFF17454C),
                          ),
                          title: const Text('漢字用字原則'),
                          subtitle: const Text('查看教育部頁面的重點整理與辭典漢字選用方式。'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showReferenceArticle(
                              context,
                              title: '漢字用字原則',
                              introduction:
                                  '這份頁面說明辭典編輯時怎麼選擇漢字。核心不是把所有口語都硬套成單一寫法，而是在語音、語義、歷史文獻與實際使用之間取得平衡，給出適合辭典檢索與教學的字形。',
                              sections: const [
                                ReferenceArticleSection(
                                  title: '選字方向',
                                  paragraphs: [
                                    '辭典會優先採用已經有一定使用基礎、語義相對明確、且能穩定對應台語詞義的字形。若沒有理想的本字，也會考慮慣用俗字或折衷寫法。',
                                  ],
                                  bullets: [
                                    '不是所有詞都能找到唯一且無爭議的本字。',
                                    '選字會同時參考音近、義近與文獻可追溯性。',
                                    '當不同寫法都流通時，辭典會選定主要詞形，讓查詢結果保持一致。',
                                  ],
                                ),
                                ReferenceArticleSection(
                                  title: '本字、借字與俗字',
                                  paragraphs: [
                                    '頁面區分了幾種常見用字來源。對使用者來說，重點是理解字形只是記錄工具，詞義與讀音才是查詞時真正要先確認的核心。',
                                  ],
                                  bullets: [
                                    '若有較可信的本字，通常會優先採用。',
                                    '若本字難以確定，可能採用約定俗成的借字或常見俗字。',
                                    '部分詞條會因教學或檢索需求，保留較容易辨識的字形。',
                                  ],
                                ),
                                ReferenceArticleSection(
                                  title: '查詞時怎麼看待漢字',
                                  paragraphs: [
                                    '對一般使用者而言，最實際的做法是把辭典漢字看成經過編輯決策後的標準入口，而不是唯一不可更動的自然答案。',
                                  ],
                                  bullets: [
                                    '看到和自己習慣不同的字形時，先比對讀音與義項，不要只看字面。',
                                    '若同音異字或同義異寫很多，優先依辭典主詞條為準。',
                                    '需要教學、寫作或註解時，可把辭典選字當作優先參考格式。',
                                  ],
                                ),
                              ],
                              sourceUrl:
                                  'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
                            );
                          },
                        ),
                        AboutListTile(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF17454C),
                          ),
                          applicationName: '台語辭典',
                          applicationLegalese:
                              'App code: MIT\nDictionary data and audio: 教育部《臺灣台語常用詞辭典》衍生內容，採 CC BY-ND 3.0 TW。',
                          aboutBoxChildren: const [
                            SizedBox(height: 12),
                            Text('台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。'),
                            SizedBox(height: 12),
                            Text(
                              '參考頁面：https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/',
                            ),
                            SizedBox(height: 8),
                            Text(
                              '臺羅標注說明：https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
                            ),
                            SizedBox(height: 8),
                            Text(
                              '漢字用字原則：https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
                            ),
                            SizedBox(height: 8),
                            Text(
                              '辭典附錄：https://sutian.moe.edu.tw/zh-hant/piantsip/sutian-huliok/',
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
