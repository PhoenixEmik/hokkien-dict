import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/settings/settings.dart';

class LocalizedReferenceArticle {
  const LocalizedReferenceArticle({
    required this.title,
    required this.introduction,
    required this.sections,
    required this.sourceUrl,
  });

  final String title;
  final String introduction;
  final List<ReferenceArticleSection> sections;
  final String sourceUrl;
}

LocalizedReferenceArticle buildTailoReferenceArticle(AppLocalizations l10n) {
  final locale = AppLocalizations.resolveLocale(l10n.locale);

  if (locale == AppLocalizations.englishLocale) {
    return const LocalizedReferenceArticle(
      title: 'Tai-lo Orthography Guide',
      introduction:
          'This page summarizes the Tai-lo romanization system used by the Ministry of Education Taiwanese Hokkien Dictionary. The app keeps entry and example spellings aligned to that standard so lookup, pronunciation study, and sharing stay consistent.',
      sections: [
        ReferenceArticleSection(
          title: 'Spelling Basics',
          paragraphs: [
            'Tai-lo is used as the primary spelling system in the dictionary. It records syllable structure, nasalization, checked endings, and tone information instead of simplifying them away.',
          ],
          bullets: [
            'Initials and finals are kept explicit so learners can inspect sound structure.',
            'Nasal vowels, glottal endings, and checked syllables are preserved in spelling.',
            'Hyphens are used to mark multi-syllable words and keep boundaries clear.',
          ],
        ),
        ReferenceArticleSection(
          title: 'Core Tones',
          paragraphs: [
            'Most entries use the main seven tone categories seen in modern Taiwanese Hokkien, with occasional references to rarer categories in specialized cases.',
          ],
          bullets: [
            'The dictionary may show both diacritic-based spelling and numeric tone notation.',
            'Checked tones must be read together with final consonants such as -p, -t, -k, or -h.',
            'Tone differences are lexical and can affect both meaning and entry ordering.',
          ],
          tables: [
            ReferenceArticleTableData(
              caption: 'Tone examples',
              headers: ['Tone', '1', '2', '3', '4', '5', '(6)', '7', '8'],
              rows: [
                [
                  'Traditional class',
                  'Yin level',
                  'Yin rising',
                  'Yin departing',
                  'Yin checked',
                  'Yang level',
                  '(Yang rising)',
                  'Yang departing',
                  'Yang checked',
                ],
                [
                  'Diacritic form',
                  'tong',
                  'tóng',
                  'tòng',
                  'tok',
                  'tông',
                  '',
                  'tōng',
                  'to̍k',
                ],
                [
                  'Numeric form',
                  'tong1',
                  'tong2',
                  'tong3',
                  'tok4',
                  'tong5',
                  '',
                  'tong7',
                  'tok8',
                ],
              ],
            ),
          ],
        ),
        ReferenceArticleSection(
          title: 'Special Marks and Neutral Tone',
          paragraphs: [
            'The guide also covers less common notations such as neutral tone and special tone values used in specific dialectal or phonological contexts.',
          ],
          bullets: [
            'A sixth tone may appear in some regional readings.',
            'The neutral-tone marker "--" signals a weakly stressed following syllable.',
            'Sequences like āu--ji̍t and tsáu--tshut-khì should not be read as if all syllables carry the same tone value.',
          ],
        ),
        ReferenceArticleSection(
          title: 'Tone Sandhi',
          paragraphs: [
            'Running speech often changes citation tones. The dictionary keeps headwords in citation tone for stable lookup, while examples still reflect natural usage contexts.',
          ],
          bullets: [
            'Common patterns include 1→7, 2→1, 3→2, and 7→3.',
            'Tone 4 and tone 8 shift differently depending on final stops or -h.',
            'Tone 5 may surface differently in Zhang- and Quan-based traditions.',
          ],
          tables: [
            ReferenceArticleTableData(
              caption: 'Common sandhi patterns',
              headers: ['Tone', 'Pattern', 'Example', 'Citation', 'Spoken'],
              rows: [
                ['1', '1→7', '心肝', 'sim-kuann', 'sīm-kuann'],
                ['2', '2→1', '小弟', 'sió-tī', 'sio-tī'],
                ['3', '3→2', '世間', 'sè-kan', 'sé-kan'],
                [
                  '4',
                  '4→8 / 4→2',
                  '出名 / 鐵馬',
                  'tshut-miâ / thih-bé',
                  'tshu̍t-miâ / thí-bé',
                ],
              ],
            ),
          ],
        ),
        ReferenceArticleSection(
          title: 'How to Use It When Searching',
          paragraphs: [
            'Treat Tai-lo as a stable lookup index. Even if you are not yet comfortable with every marker, you can start with approximate spelling and then compare the normalized form shown in the entry.',
          ],
          bullets: [
            'Identify the rough initial and final shape before guessing tone changes from sentence context.',
            'Do not ignore nasalization, checked endings, hyphens, or neutral-tone markers. They carry lexical information.',
            'If results look close but not exact, compare the entry spelling against example usage before deciding it is a mismatch.',
          ],
        ),
      ],
      sourceUrl:
          'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
    );
  }

  if (locale == AppLocalizations.simplifiedChineseLocale) {
    return const LocalizedReferenceArticle(
      title: '台罗标注说明',
      introduction:
          '这份页面整理教育部《台湾台语常用词辞典》采用的台湾台语罗马字拼音方案。App 会尽量让词目与例句都维持同一套标注方式，方便查词、比对读音与学习发音。',
      sections: [
        ReferenceArticleSection(
          title: '拼写基础',
          paragraphs: ['词典以台罗作为主要拼写系统，不会刻意省略音节结构、鼻化、入声尾或声调资讯。'],
          bullets: [
            '声母和韵母会明确保留，方便使用者对照音节结构。',
            '鼻化、喉塞与入声字尾不会被改写成口语化简写。',
            '多音节词会用连字符号标示词形边界。',
          ],
        ),
        ReferenceArticleSection(
          title: '一般声调',
          paragraphs: ['现代通行的台语资料通常会看到七个主要声调，词典也以这些调类作为主要标记基础。'],
          bullets: [
            '词典会同时出现正式调符写法与数字调写法。',
            '入声字要和 -p、-t、-k、-h 等尾音一起判读。',
            '不同调号会直接影响词义与词条排序。',
          ],
          tables: [
            ReferenceArticleTableData(
              caption: '声调举例',
              headers: ['声调', '1', '2', '3', '4', '5', '（6）', '7', '8'],
              rows: [
                [
                  '正式版',
                  'tong',
                  'tóng',
                  'tòng',
                  'tok',
                  'tông',
                  '',
                  'tōng',
                  'to̍k',
                ],
                [
                  '数字版',
                  'tong1',
                  'tong2',
                  'tong3',
                  'tok4',
                  'tong5',
                  '',
                  'tong7',
                  'tok8',
                ],
              ],
            ),
          ],
        ),
        ReferenceArticleSection(
          title: '特殊标记与轻声',
          paragraphs: ['页面也补充轻声与少数特殊调值的写法，帮助使用者看懂词条与例句里的节奏变化。'],
          bullets: [
            '部分地方音会出现第 6 声之类的特殊记号。',
            '轻声会用 "--" 标示在重读与轻读之间。',
            '像 āu--ji̍t、tsáu--tshut-khì 这类写法，重点是提醒你后段音节要弱读。',
          ],
        ),
        ReferenceArticleSection(
          title: '变调',
          paragraphs: ['词典词目原则上标本调，方便稳定查询；句中实际发音仍可能因为连读而产生变调。'],
          bullets: [
            '常见规则包括 1→7、2→1、3→2、7→3。',
            '第 4 声和第 8 声会依尾音类型出现不同变化。',
            '第 5 声在漳、泉系统下可能出现不同结果。',
          ],
          tables: [
            ReferenceArticleTableData(
              caption: '变调规则',
              headers: ['声调', '规则', '例词', '本调', '实际语音'],
              rows: [
                ['1', '1→7', '心肝', 'sim-kuann', 'sīm-kuann'],
                ['2', '2→1', '小弟', 'sió-tī', 'sio-tī'],
                ['3', '3→2', '世间', 'sè-kan', 'sé-kan'],
                [
                  '4',
                  '4→8 / 4→2',
                  '出名 / 铁马',
                  'tshut-miâ / thih-bé',
                  'tshu̍t-miâ / thí-bé',
                ],
              ],
            ),
          ],
        ),
        ReferenceArticleSection(
          title: '查询时怎么用',
          paragraphs: ['实际查询时，可以先把台罗当成稳定索引，不需要先把句中变调回推成本调拼写。'],
          bullets: [
            '先抓声母和韵母的大致形状，再确认本调。',
            '鼻化、入声尾、连字符和轻声符都不只是装饰。',
            '若结果接近但不完全一致，优先比对词条里的正式台罗标注。',
          ],
        ),
      ],
      sourceUrl:
          'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
    );
  }

  return const LocalizedReferenceArticle(
    title: '臺羅標注說明',
    introduction:
        '這份頁面整理了教育部臺灣台語常用詞辭典採用的臺灣台語羅馬字拼音方案。辭典以教育部公告的臺羅作為主要羅馬字系統，詞目與例句都盡量依同一套標記方式呈現；外來詞則視為台語詞目，標示其回推的本調。',
    sections: [
      ReferenceArticleSection(
        title: '拼寫基礎',
        paragraphs: [
          '頁面先交代辭典以臺羅作為統一拼寫基礎，目的是讓讀者在查詞、比對例句、學習發音時有一致的書寫依據。系統不只是把台語音節拼出來，還會一起保留詞內結構與本調資訊。',
        ],
        bullets: [
          '聲母與韻母會依標準臺羅拆分，讓使用者可以對照讀音結構。',
          '鼻化、喉塞與入聲字尾會保留在拼寫中，不另外改寫成口語化的簡略形式。',
          '音節之間會用連字符號標示多音節詞，讓詞形邊界更清楚。',
        ],
      ),
      ReferenceArticleSection(
        title: '一般聲調',
        paragraphs: [
          '頁面將一般聲調整理為第1聲、第2聲、第3聲、第4聲、第5聲、第7聲、第8聲。從漢語傳統調類來看，對應到陰平、陰上、陰去、陰入、陽平、陽去、陽入；現代通行腔裡，陽上通常已和陽去合流，所以一般會看到七個主要聲調。',
        ],
        bullets: [
          '辭典同時可對照正式版調符和數字版寫法，例如 tong1、tong2、tong3、tok4、tong5、tong7、tok8。',
          '入聲字會和塞音尾一起判讀，例如 -p、-t、-k、-h 的音節要連同尾音一起看。',
          '查詞時看到不同調號，不只是語氣差異，往往也會直接影響詞義和詞條排序。',
        ],
        tables: [
          ReferenceArticleTableData(
            caption: '聲調舉例',
            headers: [
              '聲調',
              '第1聲',
              '第2聲',
              '第3聲',
              '第4聲',
              '第5聲',
              '（第6聲）',
              '第7聲',
              '第8聲',
            ],
            rows: [
              ['漢語調類', '陰平', '陰上', '陰去', '陰入', '陽平', '（陽上）', '陽去', '陽入'],
              [
                '正式版',
                'tong',
                'tóng',
                'tòng',
                'tok',
                'tông',
                '',
                'tōng',
                'to̍k',
              ],
              [
                '數字版',
                'tong1',
                'tong2',
                'tong3',
                'tok4',
                'tong5',
                '',
                'tong7',
                'tok8',
              ],
              ['例字', '東', '黨', '棟', '督', '同', '（動）', '洞', '毒'],
            ],
          ),
        ],
      ),
      ReferenceArticleSection(
        title: '特殊聲調與輕聲',
        paragraphs: [
          '除了常見的七個主要聲調，頁面也補充辭典會遇到的特殊標記。這些標記不算日常入門最先學的部分，但對讀懂詞條、例句與口語節奏很重要。',
        ],
        bullets: [
          '部分地方音會出現第6聲，頁面以像 o6 這類形式舉例說明。',
          '合音與三連音的第一音節可能標成第9聲，用來表示特殊音值。',
          '輕聲用「--」標記在重讀與輕讀之間；輕聲符前面的音節唸本調，後面的音節則依輕聲處理。',
          '像 āu--ji̍t、tsáu--tshut-khì 這類寫法，重點就是提醒你不要把整串都當成同一種調值。',
        ],
      ),
      ReferenceArticleSection(
        title: '變調',
        paragraphs: [
          '頁面特別說明台語在詞句中常有連讀變調，也就是字接上後字時，實際唸出的聲調會和單字本調不同。不過變調會受斷句、語氣、弱讀與焦點影響，因此同一句話可能依不同切法出現不同實際調值。',
        ],
        bullets: [
          '頁面整理了主流變調規則，例如 1 變 7、2 變 1、3 變 2、7 變 3。',
          '第4聲與第8聲會依塞音尾或 -h 尾出現不同變化方向，所以要連同尾音一起判讀。',
          '第5聲在漳、泉系統下可能出現不同變調結果，辭典頁面也有特別提醒。',
          '本辭典為了保持查詢一致性，詞目原則上標本調，不直接標出連讀後的變調。',
        ],
        tables: [
          ReferenceArticleTableData(
            caption: '變調規則',
            headers: ['聲調', '變調規則', '例詞', '本調', '變調後實際語音'],
            rows: [
              ['第1聲', '1→7', '心肝', 'sim-kuann', 'sīm-kuann'],
              ['第2聲', '2→1', '小弟', 'sió-tī', 'sio-tī'],
              ['第3聲', '3→2', '世間', 'sè-kan', 'sé-kan'],
              ['第4聲', '4→8(-p-t-k)', '出名', 'tshut-miâ', 'tshu̍t-miâ'],
              ['', '4→2(-h)', '鐵馬', 'thih-bé', 'thí-bé'],
              ['第5聲', '5→7(漳)', '來往', 'lâi-óng', 'lāi-óng'],
              ['', '5→3(泉)', '來往', 'lâi-óng', 'lài-óng'],
              ['第7聲', '7→3', '外口', 'guā-kháu', 'guà-kháu'],
              ['第8聲', '8→4(-p-t-k)', '木瓜', 'bo̍k-kue', 'bok-kue'],
              ['', '8→3(-h)', '月娘', 'gue̍h-niû', 'guè-niû'],
            ],
          ),
        ],
      ),
      ReferenceArticleSection(
        title: '查詢時怎麼用',
        paragraphs: [
          '實際使用時，可以先把臺羅當成穩定的索引工具。即使不熟悉全部符號，也能先用基本拼法輸入，再回頭比對詞條內的正式標注。',
        ],
        bullets: [
          '先抓聲母與韻母的大致形狀，再確認本調，不要先用句中實際變調回推拼法。',
          '遇到鼻化、入聲尾、連字符與輕聲符時，不要把它們當成裝飾；它們本身就是辨識詞義的重要線索。',
          '如果查詢結果接近但不完全相同，優先比對詞條裡的正式臺羅標注，再看例句中的語境與讀音。',
        ],
      ),
    ],
    sourceUrl:
        'https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/',
  );
}

LocalizedReferenceArticle buildHanjiReferenceArticle(AppLocalizations l10n) {
  final locale = AppLocalizations.resolveLocale(l10n.locale);

  if (locale == AppLocalizations.englishLocale) {
    return const LocalizedReferenceArticle(
      title: 'Hanji Usage Principles',
      introduction:
          'This page explains how the dictionary chooses Hanji forms. The goal is not to force every spoken Taiwanese word into a single written shape, but to balance sound, meaning, textual evidence, common usage, and readability.',
      sections: [
        ReferenceArticleSection(
          title: 'Current Writing Situation',
          paragraphs: [
            'Taiwanese Hokkien and Mandarin differ in sound system, vocabulary, and syntax. Because Taiwanese did not develop a single universally adopted writing standard, many words still have competing Hanji spellings.',
          ],
          bullets: [
            'The same word may appear with different characters in different traditions.',
            'Etymological research and practical readability do not always point to the same choice.',
            'Character choice affects learning, searchability, and digital circulation.',
          ],
        ),
        ReferenceArticleSection(
          title: 'Main Character Types',
          paragraphs: [
            'The dictionary broadly groups its preferred written forms into historically grounded characters, semantic loan uses, and substitute or newly created characters when needed.',
          ],
          bullets: [
            'Original characters are preferred when there is solid textual support and semantic continuity.',
            'Semantic loan characters borrow meaning rather than sound.',
            'Popular substitutes or newly created forms may still be used when they are more practical for readers.',
          ],
        ),
        ReferenceArticleSection(
          title: 'Substitute Characters',
          paragraphs: [
            'Non-original forms are treated as substitute characters. The dictionary does not reject them automatically, because actual literacy practice and discoverability matter too.',
          ],
          bullets: [
            'Rare original forms may be avoided if typical readers cannot recognize them.',
            'Very unfamiliar characters can create more friction than benefit in search and teaching.',
            'Established common forms may remain the main display form when they are already widely understood.',
          ],
        ),
        ReferenceArticleSection(
          title: 'Recommended Usage',
          paragraphs: [
            'The Ministry of Education has published recommended Taiwanese Hanji forms. The dictionary uses that work as an important baseline instead of treating character choice as arbitrary.',
          ],
          bullets: [
            'When you see a different character from your habit, compare pronunciation and meaning first.',
            'In cases with many homophones or variant writings, the dictionary headword can serve as the preferred entry point.',
            'For teaching or normalized writing, the headword form is usually the most stable starting point.',
          ],
        ),
      ],
      sourceUrl:
          'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
    );
  }

  if (locale == AppLocalizations.simplifiedChineseLocale) {
    return const LocalizedReferenceArticle(
      title: '汉字用字原则',
      introduction:
          '这份页面说明词典编辑时如何选择汉字。重点不是把所有台语口语硬套成单一写法，而是在语音、语义、文献依据、使用现况与可读性之间取得平衡。',
      sections: [
        ReferenceArticleSection(
          title: '汉字状况',
          paragraphs: ['台语和华语在语音、词汇、句法上本来就有差异，加上台语长期缺少统一文字规范，所以许多词一直存在多种写法。'],
          bullets: [
            '同一个词可能会对应不同字形。',
            '学理考证与读者可读性不一定总是指向同一个答案。',
            '用字选择会影响教学、检索与流通成本。',
          ],
        ),
        ReferenceArticleSection(
          title: '本辞典的用字类型',
          paragraphs: ['词典会综合考虑本字、训用字、俗字与必要时的新造字，并尽量维持一音节对应一个主要字形。'],
          bullets: ['本字通常是最优先考虑的类型。', '训用字是借字义不借字音。', '俗字或替代字在可读性与使用习惯上有时更实用。'],
        ),
        ReferenceArticleSection(
          title: '替代字说明',
          paragraphs: ['词典不会因为找到可能的本字，就完全排除读者更熟悉的替代字。'],
          bullets: [
            '太冷僻或太难辨识的本字可能不利于一般使用。',
            '若替代字已经广泛约定俗成，词典可能保留它作为主要入口。',
            '选择字形时也会考虑是否容易让读者联想到读音与意义。',
          ],
        ),
        ReferenceArticleSection(
          title: '推荐用字',
          paragraphs: ['教育部曾公布一批台湾台语推荐用字，词典会以这些成果作为重要基础。'],
          bullets: [
            '遇到习惯不同的字形时，先比对读音与义项。',
            '同音异字很多时，可以把词典主词条当作优先参考。',
            '若要做教学或标准化书写，词典主用字通常最稳妥。',
          ],
        ),
      ],
      sourceUrl:
          'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
    );
  }

  return const LocalizedReferenceArticle(
    title: '漢字用字原則',
    introduction:
        '這份頁面說明辭典編輯時怎麼選擇漢字。核心不是把所有台語口語都硬套成單一寫法，而是在語音、語義、歷史文獻、使用現況與資訊流通之間取得平衡，給出適合辭典檢索與教學的字形。',
    sections: [
      ReferenceArticleSection(
        title: '漢字狀況',
        paragraphs: [
          '頁面先說明臺灣台語和華語在語音、詞彙、句法上本來就有不少差異，而且台語長期沒有像共通語那樣完成統一文字規範，所以現行用字一直相當分歧。',
          '雖然歷來詞書和學界對不少「本字」已有越來越穩定的考證，但仍然有不少詞來源不明，甚至根本不是漢語來源，於是就出現「有音無穩定漢字」的狀況。',
        ],
        bullets: [
          '同一個詞在不同書寫傳統裡可能會對應不同字形。',
          '辭典編輯必須在學理考證和讀者實際可用性之間做取捨。',
          '因此字形不只是語源問題，也牽涉教學、檢索和流通成本。',
        ],
      ),
      ReferenceArticleSection(
        title: '本辭典的用字類型',
        paragraphs: [
          '頁面將辭典主要用字分成幾種型態。大方向上，辭典仍以漢字書寫為基礎，而且傾向一個音節對應一個字形，再依既定編輯概念選定主用字。',
        ],
        bullets: [
          '本字：在傳統文獻中已有字形，而且字義和台語詞彙有同源關係；這通常是最優先考慮的類型。',
          '訓用字：借字義不借字音，用華語讀音和台語讀音不同的既有漢字來表達相同詞義。',
          '俗字：包含借音字與新造字。借音字是借近音字形來記錄別的詞義；新造字則是在找不到可用字時另外造字。',
        ],
      ),
      ReferenceArticleSection(
        title: '替代字說明',
        paragraphs: [
          '頁面把非本字的寫法統稱為「替代字」。辭典原則上傾向本字，但不是一旦找到本字就一定使用，因為實際閱讀與流通情況也必須納入考量。',
        ],
        bullets: [
          '若本字太冷僻、太難辨識，一般讀者幾乎不會用，辭典可能改採較常見的替代字。',
          '若本字和標準語日常基本字差異過大，反而會增加閱讀阻礙，辭典也可能改用較直觀的字形。',
          '若俗字已經廣泛約定俗成，不易改變使用習慣，辭典也可能沿用俗字而不強推考證本字。',
          '選字時還會考慮「望字生音義」的效果，也就是讓讀者看到字形時比較容易同時聯想到讀音和意義。',
          '另外也盡量避免無限制造字，因為造字太多會增加電腦輸入、字型支援、學習與流通上的阻礙。',
        ],
      ),
      ReferenceArticleSection(
        title: '推薦用字',
        paragraphs: [
          '頁面最後指出，教育部曾公告一批「臺灣台語推薦用字」，本辭典原則上會參照該成果來擬定實際用字。也就是說，辭典不是完全自由選字，而是盡量建立在既有官方整理基礎上。',
        ],
        bullets: [
          '查詢時若看到和自己習慣不同的字形，先比對讀音與義項，不要只看字面。',
          '遇到同音異字、同義異寫很多的情況，可以把辭典主詞條當作優先參考入口。',
          '需要教學、整理筆記或做標準化書寫時，辭典主用字通常是最穩定的起點。',
        ],
      ),
    ],
    sourceUrl:
        'https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/',
  );
}
