import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const Locale englishLocale = Locale('en');
  static const Locale simplifiedChineseLocale = Locale('zh', 'CN');
  static const Locale traditionalChineseLocale = Locale('zh', 'TW');

  static const supportedLocales = <Locale>[
    englishLocale,
    simplifiedChineseLocale,
    traditionalChineseLocale,
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations is missing from context.');
    return localizations!;
  }

  static Locale resolveLocale(Locale? locale) {
    if (locale == null) {
      return englishLocale;
    }

    if (locale.languageCode == 'zh') {
      final scriptCode = locale.scriptCode?.toLowerCase();
      final countryCode = locale.countryCode?.toUpperCase();
      if (scriptCode == 'hans' || countryCode == 'CN' || countryCode == 'SG') {
        return simplifiedChineseLocale;
      }
      return traditionalChineseLocale;
    }

    if (locale.languageCode == 'en') {
      return englishLocale;
    }

    return englishLocale;
  }

  static Locale resolveLocaleList(
    List<Locale>? locales,
    Iterable<Locale> supportedLocales,
  ) {
    for (final locale in locales ?? const <Locale>[]) {
      final resolved = resolveLocale(locale);
      if (supportedLocales.contains(resolved)) {
        return resolved;
      }
    }
    return englishLocale;
  }

  static String localeStorageValue(Locale locale) =>
      resolveLocale(locale).toLanguageTag();

  static Locale? localeFromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final locale in supportedLocales) {
      if (locale.toLanguageTag() == value) {
        return locale;
      }
    }
    return null;
  }

  String get _languageTag => resolveLocale(locale).toLanguageTag();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Hokkien Dictionary',
      'dictionaryTab': 'Dictionary',
      'bookmarksTab': 'Bookmarks',
      'settingsTab': 'Settings',
      'searchHint': 'Search Taiwanese, romanization, or Mandarin',
      'clearSearch': 'Clear search',
      'searchHistory': 'Search History',
      'clearSearchHistory': 'Clear search history',
      'startSearch': 'Start Searching',
      'startSearchBody':
          'Enter Taiwanese characters, romanization, or a Mandarin meaning to see entries.',
      'noResultsTitle': 'No matching results',
      'noResultsBody': 'Try another spelling or use a different query.',
      'noResultsShort': 'No matching entries found',
      'tabletPreviewEmptyTitle': 'Select an entry',
      'tabletPreviewEmptyBody':
          'Pick a result from the list to preview its details here.',
      'bookmarksTitle': 'Bookmarks',
      'bookmarksEmptyTitle': 'No bookmarks yet',
      'bookmarksEmptyBody':
          'Bookmark a word from the detail page and it will appear here.',
      'settingsTitle': 'Settings',
      'offlineResources': 'Offline Resources',
      'appearance': 'Appearance',
      'about': 'About',
      'advancedSettings': 'Advanced Settings',
      'advancedSettingsSubtitle':
          'Manage maintenance and database rebuild actions.',
      'offlineResourceMaintenance': 'Offline Resource Maintenance',
      'languageSetting': 'Language / 語言',
      'theme': 'Theme',
      'displayMode': 'Display mode',
      'fontSize': 'Font Size',
      'small': 'Small',
      'extraLarge': 'Extra Large',
      'textScaleSmall': 'Smaller',
      'textScaleDefault': 'Default',
      'textScaleLarge': 'Larger',
      'textScaleExtraLarge': 'Extra Large',
      'themeSystem': 'Follow system',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeAmoled': 'AMOLED Black',
      'dictionarySourceArchive': 'Dictionary Source File',
      'dictionarySourceSubtitle':
          'Included in the app and can also be re-downloaded to rebuild the local SQLite dictionary.',
      'dictionarySourceReady':
          'Available and ready to rebuild the local dictionary database',
      'audioWordArchive': 'Word Audio',
      'audioSentenceArchive': 'Example Audio',
      'rebuildDictionaryDatabase': 'Rebuild Dictionary Database',
      'rebuildDictionaryDatabaseSubtitle':
          'Recreate the local SQLite dictionary from the available kautian.ods file.',
      'rebuildingDictionaryDatabase': 'Rebuilding dictionary database...',
      'rebuildDictionaryDatabaseSuccess':
          'Dictionary database rebuilt successfully.',
      'downloadDictionarySourceFirst':
          'Please make the dictionary source file (kautian.ods) available first.',
      'dictionarySourceCorrupted':
          'The local kautian.ods file is empty or corrupted. It will be downloaded again.',
      'initializingAppTitle': 'Preparing Offline Dictionary',
      'initializationBlockingNotice':
          'The app is preparing and building the local dictionary before search becomes available.',
      'initializationCheckingResources': 'Checking local resources...',
      'initializationDownloadingSource': 'Downloading kautian.ods...',
      'initializationParsingSource': 'Parsing dictionary source...',
      'initializationWritingDatabase': 'Writing local SQLite database...',
      'initializationFinalizingDatabase': 'Finalizing local dictionary...',
      'initializationFailed': 'Initialization failed',
      'initializationRetryHint':
          'Fix the issue and try again. The app will stay locked until the local dictionary is ready.',
      'retryInitialization': 'Retry initialization',
      'confirmRebuildDictionaryTitle': 'Confirm Rebuild?',
      'confirmRebuildDictionaryBody':
          'This will take some time and overwrite the current dictionary data with the available source file. Are you sure you want to proceed?',
      'cancelAction': 'Cancel',
      'confirmAction': 'Confirm',
      'loadingAudioPrefix': 'Loading',
      'playAudioPrefix': 'Play',
      'stopAudioPrefix': 'Stop',
      'download': 'Download',
      'pause': 'Pause',
      'resume': 'Resume',
      'retry': 'Retry',
      'redownload': 'Re-download',
      'unknownSize': 'unknown size',
      'downloadReady': 'Downloaded and ready for offline playback',
      'downloadApproxPrefix': 'About',
      'tailoGuide': 'Tai-lo Orthography Guide',
      'tailoGuideSubtitle':
          'Read a summary of the ministry guide and Tai-lo spelling rules.',
      'hanjiGuide': 'Hanji Usage Principles',
      'hanjiGuideSubtitle':
          'Read a summary of the ministry guide and character selection rules.',
      'aboutApp': 'About Hokkien Dictionary',
      'aboutAppSubtitle': 'Author, version, licenses, and project information.',
      'aboutDescription':
          'Hokkien Dictionary provides offline bidirectional lookup between Taiwanese and Mandarin, with downloadable ministry audio for words and examples.',
      'aboutVersion': 'Version',
      'aboutAuthor': 'Author',
      'aboutRepository': 'GitHub',
      'aboutRepositorySubtitle': 'Source code and releases',
      'aboutResources': 'References',
      'aboutLicenses': 'Licenses',
      'privacyPolicy': 'Privacy Policy',
      'privacyPolicySubtitle':
          'Read how the app stores local data, uses network access, and handles sharing.',
      'licenseInformation': 'License Information',
      'appCodeLicense': 'App code',
      'appCodeLicenseDescription': 'MIT License',
      'dictionaryDataLicense': 'Dictionary data',
      'dictionaryDataLicenseDescription':
          'Derived from the Ministry of Education Taiwanese Hokkien Dictionary. Licensed under CC BY-ND 3.0 TW.',
      'dictionaryAudioLicense': 'Dictionary audio',
      'dictionaryAudioLicenseDescription':
          'Derived from the Ministry of Education Taiwanese Hokkien Dictionary audio. Licensed under CC BY-ND 3.0 TW.',
      'ministryCopyrightNote': 'Ministry copyright note',
      'flutterLicenses': 'Flutter and package licenses',
      'flutterLicensesDescription':
          'View detailed open-source licenses bundled by Flutter.',
      'referencePage': 'Reference page',
      'shareEntry': 'Share entry',
      'addBookmark': 'Add bookmark',
      'removeBookmark': 'Remove bookmark',
      'wordDetailFallbackTitle': 'Entry Details',
      'english': 'English',
      'simplifiedChinese': '简体中文',
      'traditionalChinese': '繁體中文',
    },
    'zh-CN': {
      'appTitle': '台语辞典',
      'dictionaryTab': '词典',
      'bookmarksTab': '书签',
      'settingsTab': '设置',
      'searchHint': '输入台语汉字、白话字或华语词义',
      'clearSearch': '清除搜索内容',
      'searchHistory': '搜索记录',
      'clearSearchHistory': '清除搜索记录',
      'startSearch': '开始搜索',
      'startSearchBody': '输入台语汉字、白话字或华语释义后才显示词条。',
      'noResultsTitle': '找不到符合的结果',
      'noResultsBody': '换个写法试试看，或改用另一个查询方向。',
      'noResultsShort': '找不到符合的词条',
      'tabletPreviewEmptyTitle': '选择词条',
      'tabletPreviewEmptyBody': '从左侧结果列表选择一个词条后，会在这里显示详细内容。',
      'bookmarksTitle': '书签',
      'bookmarksEmptyTitle': '尚未加入任何书签',
      'bookmarksEmptyBody': '从词条详细页点选书签图示，就会显示在这里。',
      'settingsTitle': '设置',
      'offlineResources': '离线资源',
      'appearance': '外观',
      'about': '关于',
      'advancedSettings': '进阶设置',
      'advancedSettingsSubtitle': '管理维护动作与词典资料库重建。',
      'offlineResourceMaintenance': '离线资源维护',
      'languageSetting': 'Language / 語言',
      'theme': '主题',
      'displayMode': '显示模式',
      'fontSize': '字级',
      'small': '小',
      'extraLarge': '特大',
      'textScaleSmall': '较小',
      'textScaleDefault': '标准',
      'textScaleLarge': '较大',
      'textScaleExtraLarge': '特大',
      'themeSystem': '跟随系统',
      'themeLight': '浅色',
      'themeDark': '深色',
      'themeAmoled': 'AMOLED 黑',
      'dictionarySourceArchive': '词典原始档',
      'dictionarySourceSubtitle': 'App 已内建 kautian.ods，也可重新下载后再重建本机 SQLite 词典资料库。',
      'dictionarySourceReady': '来源档已就绪，可用于重新构建本机词典资料库',
      'audioWordArchive': '词目音档',
      'audioSentenceArchive': '例句音档',
      'rebuildDictionaryDatabase': '重新构建词典资料库',
      'rebuildDictionaryDatabaseSubtitle':
          '从目前可用的 kautian.ods 重新建立本机 SQLite 词典资料库。',
      'rebuildingDictionaryDatabase': '正在重新构建词典资料库…',
      'rebuildDictionaryDatabaseSuccess': '词典资料库已重新构建完成。',
      'downloadDictionarySourceFirst': '请先让词典原始档 (kautian.ods) 处于可用状态',
      'dictionarySourceCorrupted': '本地 kautian.ods 为空或已损坏，系统会重新下载。',
      'initializingAppTitle': '准备离线词典',
      'initializationBlockingNotice': '系统会先准备并建立本机词典资料库，完成前无法进入搜索。',
      'initializationCheckingResources': '正在检查本地资源…',
      'initializationDownloadingSource': '正在下载 kautian.ods…',
      'initializationParsingSource': '正在解析词典原始档…',
      'initializationWritingDatabase': '正在写入本机 SQLite 词典资料库…',
      'initializationFinalizingDatabase': '正在完成本机词典资料库…',
      'initializationFailed': '初始化失败',
      'initializationRetryHint': '请排除问题后再重试，完成前 app 会维持锁定状态。',
      'retryInitialization': '重新尝试初始化',
      'confirmRebuildDictionaryTitle': '确认重新构建资料库？',
      'confirmRebuildDictionaryBody': '这将会花费一些时间，并以目前可用的原始档覆盖现有的词典资料。您确定要继续吗？',
      'cancelAction': '取消',
      'confirmAction': '确定',
      'loadingAudioPrefix': '正在载入',
      'playAudioPrefix': '播放',
      'stopAudioPrefix': '停止播放',
      'download': '下载',
      'pause': '暂停',
      'resume': '继续',
      'retry': '重试',
      'redownload': '重新下载',
      'unknownSize': '未知大小',
      'downloadReady': '已下载，可离线播放',
      'downloadApproxPrefix': '大小约',
      'tailoGuide': '台罗标注说明',
      'tailoGuideSubtitle': '查看教育部页面的重点整理与台罗拼写原则。',
      'hanjiGuide': '汉字用字原则',
      'hanjiGuideSubtitle': '查看教育部页面的重点整理与辞典汉字选用方式。',
      'aboutApp': '关于台语辞典',
      'aboutAppSubtitle': '作者、版本、授权与项目资讯。',
      'aboutDescription': '台语辞典提供离线的台语与华语双向查询，并支持下载教育部词目与例句音档。',
      'aboutVersion': '版本',
      'aboutAuthor': '作者',
      'aboutRepository': 'GitHub',
      'aboutRepositorySubtitle': '原始码与发行版本',
      'aboutResources': '参考资料',
      'aboutLicenses': '授权资讯',
      'privacyPolicy': '隐私政策',
      'privacyPolicySubtitle': '查看 App 如何保存本地资料、使用网路，以及处理分享行为。',
      'licenseInformation': '授权资讯',
      'appCodeLicense': 'App 程式码',
      'appCodeLicenseDescription': 'MIT 授权',
      'dictionaryDataLicense': '词典资料',
      'dictionaryDataLicenseDescription':
          '衍生自教育部《台湾台语常用词辞典》，采用 CC BY-ND 3.0 TW。',
      'dictionaryAudioLicense': '词典音档',
      'dictionaryAudioLicenseDescription':
          '衍生自教育部《台湾台语常用词辞典》音档，采用 CC BY-ND 3.0 TW。',
      'ministryCopyrightNote': '教育部版权说明',
      'flutterLicenses': 'Flutter 与套件授权',
      'flutterLicensesDescription': '查看 Flutter 汇整的开源套件详细授权。',
      'referencePage': '参考页面',
      'shareEntry': '分享词条',
      'addBookmark': '加入书签',
      'removeBookmark': '移除书签',
      'wordDetailFallbackTitle': '词条详细资料',
      'english': 'English',
      'simplifiedChinese': '简体中文',
      'traditionalChinese': '繁體中文',
    },
    'zh-TW': {
      'appTitle': '台語辭典',
      'dictionaryTab': '辭典',
      'bookmarksTab': '書籤',
      'settingsTab': '設定',
      'searchHint': '輸入台語漢字、白話字或華語詞義',
      'clearSearch': '清除搜尋內容',
      'searchHistory': '搜尋紀錄',
      'clearSearchHistory': '清除搜尋紀錄',
      'startSearch': '開始搜尋',
      'startSearchBody': '輸入台語漢字、白話字，或華語釋義後才顯示詞條。',
      'noResultsTitle': '找不到符合的結果',
      'noResultsBody': '換個寫法試試看，或改用另一個查詢方向。',
      'noResultsShort': '找不到符合的詞條',
      'tabletPreviewEmptyTitle': '選擇詞條',
      'tabletPreviewEmptyBody': '從左側結果列表選擇一個詞條後，會在這裡顯示詳細內容。',
      'bookmarksTitle': '書籤',
      'bookmarksEmptyTitle': '尚未加入任何書籤',
      'bookmarksEmptyBody': '從詞條詳細頁點選書籤圖示，就會顯示在這裡。',
      'settingsTitle': '設定',
      'offlineResources': '離線資源',
      'appearance': '外觀',
      'about': '關於',
      'advancedSettings': '進階設定',
      'advancedSettingsSubtitle': '管理維護動作與詞典資料庫重建。',
      'offlineResourceMaintenance': '離線資源維護',
      'languageSetting': 'Language / 語言',
      'theme': '主題',
      'displayMode': '顯示模式',
      'fontSize': '字級',
      'small': '小',
      'extraLarge': '特大',
      'textScaleSmall': '較小',
      'textScaleDefault': '標準',
      'textScaleLarge': '較大',
      'textScaleExtraLarge': '特大',
      'themeSystem': '跟隨系統',
      'themeLight': '淺色',
      'themeDark': '深色',
      'themeAmoled': 'AMOLED 黑',
      'dictionarySourceArchive': '詞典原始檔',
      'dictionarySourceSubtitle': 'App 已內建 kautian.ods，也可重新下載後再重建本機 SQLite 詞典資料庫。',
      'dictionarySourceReady': '來源檔已就緒，可用於重新構建本機詞典資料庫',
      'audioWordArchive': '詞目音檔',
      'audioSentenceArchive': '例句音檔',
      'rebuildDictionaryDatabase': '重新構建詞典資料庫',
      'rebuildDictionaryDatabaseSubtitle':
          '從目前可用的 kautian.ods 重新建立本機 SQLite 詞典資料庫。',
      'rebuildingDictionaryDatabase': '正在重新構建詞典資料庫…',
      'rebuildDictionaryDatabaseSuccess': '詞典資料庫已重新構建完成。',
      'downloadDictionarySourceFirst': '請先讓詞典原始檔 (kautian.ods) 處於可用狀態',
      'dictionarySourceCorrupted': '本地 kautian.ods 為空或已損壞，系統會重新下載。',
      'initializingAppTitle': '準備離線詞典',
      'initializationBlockingNotice': '系統會先準備並建立本機詞典資料庫，完成前無法進入搜尋。',
      'initializationCheckingResources': '正在檢查本地資源…',
      'initializationDownloadingSource': '正在下載 kautian.ods…',
      'initializationParsingSource': '正在解析詞典原始檔…',
      'initializationWritingDatabase': '正在寫入本機 SQLite 詞典資料庫…',
      'initializationFinalizingDatabase': '正在完成本機詞典資料庫…',
      'initializationFailed': '初始化失敗',
      'initializationRetryHint': '請排除問題後再重試，完成前 app 會維持鎖定狀態。',
      'retryInitialization': '重新嘗試初始化',
      'confirmRebuildDictionaryTitle': '確認重新構建資料庫？',
      'confirmRebuildDictionaryBody': '這將會花費一些時間，並以目前可用的原始檔覆蓋現有的詞典資料。您確定要繼續嗎？',
      'cancelAction': '取消',
      'confirmAction': '確定',
      'loadingAudioPrefix': '正在載入',
      'playAudioPrefix': '播放',
      'stopAudioPrefix': '停止播放',
      'download': '下載',
      'pause': '暫停',
      'resume': '繼續',
      'retry': '重試',
      'redownload': '重新下載',
      'unknownSize': '未知大小',
      'downloadReady': '已下載，可離線播放',
      'downloadApproxPrefix': '大小約',
      'tailoGuide': '臺羅標注說明',
      'tailoGuideSubtitle': '查看教育部頁面的重點整理與台羅拼寫原則。',
      'hanjiGuide': '漢字用字原則',
      'hanjiGuideSubtitle': '查看教育部頁面的重點整理與辭典漢字選用方式。',
      'aboutApp': '關於台語辭典',
      'aboutAppSubtitle': '作者、版本、授權與專案資訊。',
      'aboutDescription': '台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。',
      'aboutVersion': '版本',
      'aboutAuthor': '作者',
      'aboutRepository': 'GitHub',
      'aboutRepositorySubtitle': '原始碼與發行版本',
      'aboutResources': '參考資料',
      'aboutLicenses': '授權資訊',
      'privacyPolicy': '隱私權政策',
      'privacyPolicySubtitle': '查看 App 如何保存本機資料、使用網路，以及處理分享行為。',
      'licenseInformation': '授權資訊',
      'appCodeLicense': 'App 程式碼',
      'appCodeLicenseDescription': 'MIT 授權',
      'dictionaryDataLicense': '詞典資料',
      'dictionaryDataLicenseDescription':
          '衍生自教育部《臺灣台語常用詞辭典》，採 CC BY-ND 3.0 TW。',
      'dictionaryAudioLicense': '詞典音檔',
      'dictionaryAudioLicenseDescription':
          '衍生自教育部《臺灣台語常用詞辭典》音檔，採 CC BY-ND 3.0 TW。',
      'ministryCopyrightNote': '教育部著作權說明',
      'flutterLicenses': 'Flutter 與套件授權',
      'flutterLicensesDescription': '查看 Flutter 彙整的開源套件詳細授權。',
      'referencePage': '參考頁面',
      'shareEntry': '分享詞條',
      'addBookmark': '加入書籤',
      'removeBookmark': '移除書籤',
      'wordDetailFallbackTitle': '詞條詳細資料',
      'english': 'English',
      'simplifiedChinese': '简体中文',
      'traditionalChinese': '繁體中文',
    },
  };

  String _text(String key) =>
      _localizedValues[_languageTag]?[key] ?? _localizedValues['en']![key]!;

  String _selectText(
    String english,
    String simplifiedChinese,
    String traditionalChinese,
  ) {
    return switch (_languageTag) {
      'zh-CN' => simplifiedChinese,
      'zh-TW' => traditionalChinese,
      _ => english,
    };
  }

  String get appTitle => _text('appTitle');
  String get dictionaryTab => _text('dictionaryTab');
  String get bookmarksTab => _text('bookmarksTab');
  String get settingsTab => _text('settingsTab');
  String get searchHint => _text('searchHint');
  String get clearSearch => _text('clearSearch');
  String get searchHistory => _text('searchHistory');
  String get clearSearchHistory => _text('clearSearchHistory');
  String get startSearch => _text('startSearch');
  String get startSearchBody => _text('startSearchBody');
  String get noResultsTitle => _text('noResultsTitle');
  String get noResultsBody => _text('noResultsBody');
  String get noResultsShort => _text('noResultsShort');
  String get tabletPreviewEmptyTitle => _text('tabletPreviewEmptyTitle');
  String get tabletPreviewEmptyBody => _text('tabletPreviewEmptyBody');
  String get bookmarksTitle => _text('bookmarksTitle');
  String get bookmarksEmptyTitle => _text('bookmarksEmptyTitle');
  String get bookmarksEmptyBody => _text('bookmarksEmptyBody');
  String get settingsTitle => _text('settingsTitle');
  String get offlineResources => _text('offlineResources');
  String get appearance => _text('appearance');
  String get about => _text('about');
  String get advancedSettings => _text('advancedSettings');
  String get advancedSettingsSubtitle => _text('advancedSettingsSubtitle');
  String get offlineResourceMaintenance => _text('offlineResourceMaintenance');
  String get languageSetting => _text('languageSetting');
  String get theme => _text('theme');
  String get displayMode => _text('displayMode');
  String get fontSize => _text('fontSize');
  String get small => _text('small');
  String get extraLarge => _text('extraLarge');
  String get dictionarySourceArchive => _text('dictionarySourceArchive');
  String get dictionarySourceSubtitle => _text('dictionarySourceSubtitle');
  String get dictionarySourceReady => _text('dictionarySourceReady');
  String get audioWordArchive => _text('audioWordArchive');
  String get audioSentenceArchive => _text('audioSentenceArchive');
  String get rebuildDictionaryDatabase => _text('rebuildDictionaryDatabase');
  String get rebuildDictionaryDatabaseSubtitle =>
      _text('rebuildDictionaryDatabaseSubtitle');
  String get rebuildingDictionaryDatabase =>
      _text('rebuildingDictionaryDatabase');
  String get rebuildDictionaryDatabaseSuccess =>
      _text('rebuildDictionaryDatabaseSuccess');
  String get downloadDictionarySourceFirst =>
      _text('downloadDictionarySourceFirst');
  String get dictionarySourceCorrupted => _text('dictionarySourceCorrupted');
  String get initializingAppTitle => _text('initializingAppTitle');
  String get initializationBlockingNotice =>
      _text('initializationBlockingNotice');
  String get initializationCheckingResources =>
      _text('initializationCheckingResources');
  String get initializationDownloadingSource =>
      _text('initializationDownloadingSource');
  String get initializationParsingSource =>
      _text('initializationParsingSource');
  String get initializationWritingDatabase =>
      _text('initializationWritingDatabase');
  String get initializationFinalizingDatabase =>
      _text('initializationFinalizingDatabase');
  String get initializationFailed => _text('initializationFailed');
  String get initializationRetryHint => _text('initializationRetryHint');
  String get retryInitialization => _text('retryInitialization');
  String get confirmRebuildDictionaryTitle =>
      _text('confirmRebuildDictionaryTitle');
  String get confirmRebuildDictionaryBody =>
      _text('confirmRebuildDictionaryBody');
  String get cancelAction => _text('cancelAction');
  String get confirmAction => _text('confirmAction');
  String get loadingAudioPrefix => _text('loadingAudioPrefix');
  String get playAudioPrefix => _text('playAudioPrefix');
  String get stopAudioPrefix => _text('stopAudioPrefix');
  String get download => _text('download');
  String get pause => _text('pause');
  String get resume => _text('resume');
  String get retry => _text('retry');
  String get redownload => _text('redownload');
  String get unknownSize => _text('unknownSize');
  String get downloadReady => _text('downloadReady');
  String get tailoGuide => _text('tailoGuide');
  String get tailoGuideSubtitle => _text('tailoGuideSubtitle');
  String get hanjiGuide => _text('hanjiGuide');
  String get hanjiGuideSubtitle => _text('hanjiGuideSubtitle');
  String get aboutApp => _text('aboutApp');
  String get aboutAppSubtitle => _text('aboutAppSubtitle');
  String get aboutDescription => _text('aboutDescription');
  String get aboutVersion => _text('aboutVersion');
  String get aboutAuthor => _text('aboutAuthor');
  String get aboutRepository => _text('aboutRepository');
  String get aboutRepositorySubtitle => _text('aboutRepositorySubtitle');
  String get aboutResources => _text('aboutResources');
  String get aboutLicenses => _text('aboutLicenses');
  String get privacyPolicy => _text('privacyPolicy');
  String get privacyPolicySubtitle => _text('privacyPolicySubtitle');
  String get licenseInformation => _text('licenseInformation');
  String get appCodeLicense => _text('appCodeLicense');
  String get appCodeLicenseDescription => _text('appCodeLicenseDescription');
  String get dictionaryDataLicense => _text('dictionaryDataLicense');
  String get dictionaryDataLicenseDescription =>
      _text('dictionaryDataLicenseDescription');
  String get dictionaryAudioLicense => _text('dictionaryAudioLicense');
  String get dictionaryAudioLicenseDescription =>
      _text('dictionaryAudioLicenseDescription');
  String get ministryCopyrightNote => _text('ministryCopyrightNote');
  String get flutterLicenses => _text('flutterLicenses');
  String get flutterLicensesDescription => _text('flutterLicensesDescription');
  String get referencePage => _text('referencePage');
  String get shareEntry => _text('shareEntry');
  String get addBookmark => _text('addBookmark');
  String get removeBookmark => _text('removeBookmark');
  String get wordDetailFallbackTitle => _text('wordDetailFallbackTitle');
  String get english => _text('english');
  String get simplifiedChinese => _text('simplifiedChinese');
  String get traditionalChinese => _text('traditionalChinese');
  String get entryOpenDetailsHint => _selectText(
    'Double tap to open entry details',
    '双击开启词条详细资料',
    '雙擊開啟詞條詳細資料',
  );
  String get unlabeledHanji =>
      _selectText('Hanji not provided', '未标记汉字', '未標記漢字');
  String get shareEntryTitleFallback =>
      _selectText('Hokkien Dictionary Entry', '台语辞典词条', '台語辭典詞條');
  String get shareEntryFooter => _selectText(
    '-- Shared from Hokkien Dictionary',
    '-- 来自台语辞典 App',
    '-- 來自台語辭典 App',
  );
  String get referenceSource => _selectText('Source', '资料来源', '資料來源');
  String get dictionaryDatabaseRebuilt => _selectText(
    'Dictionary database rebuilt.',
    '词典资料库已重新构建完成。',
    '詞典資料庫已重新構建完成。',
  );
  String get dictionarySourceInitFailed => _selectText(
    'Unable to initialize dictionary source storage.',
    '目前无法初始化词典原始档储存空间。',
    '目前無法初始化詞典原始檔儲存空間。',
  );
  String get audioStorageInitFailed => _selectText(
    'Unable to initialize offline audio storage.',
    '目前无法初始化离线音档储存空间。',
    '目前無法初始化離線音檔儲存空間。',
  );
  String get audioStorageNotReady => _selectText(
    'Offline audio storage is not ready yet.',
    '离线音档储存空间尚未准备好。',
    '離線音檔儲存空間尚未準備好。',
  );
  String get audioArchiveInvalidContent => _selectText(
    'Downloaded content format is invalid.',
    '下载内容格式不正确',
    '下載內容格式不正確',
  );
  String get offlineAudioNotInitialized => _selectText(
    'Offline audio is still initializing.',
    '离线音档功能尚未初始化完成。',
    '離線音檔功能尚未初始化完成。',
  );
  String get downloadFailed => _selectText('Download failed', '下载失败', '下載失敗');
  String get zipLocalHeaderInvalid => _selectText(
    'The ZIP local header is invalid.',
    'zip 的 local header 格式不正确。',
    'zip 的 local header 格式不正確。',
  );
  String get zipIndexNotFound => _selectText(
    'ZIP index information was not found.',
    '找不到 zip 索引资讯。',
    '找不到 zip 索引資訊。',
  );
  String get networkInterrupted =>
      _selectText('Network connection was interrupted', '网路连接中断', '網路連線中斷');
  String get aboutLegalese => _selectText(
    'App code: MIT\nDictionary data and audio: Derived from the Ministry of Education Taiwanese Hokkien Dictionary, licensed under CC BY-ND 3.0 TW.',
    'App code: MIT\nDictionary data and audio: 教育部《台湾台语常用词辞典》衍生内容，采 CC BY-ND 3.0 TW。',
    'App code: MIT\nDictionary data and audio: 教育部《臺灣台語常用詞辭典》衍生內容，採 CC BY-ND 3.0 TW。',
  );

  String readingTextScaleLabel(double value) {
    if (value <= 0.95) {
      return _text('textScaleSmall');
    }
    if (value >= 1.35) {
      return _text('textScaleExtraLarge');
    }
    if (value >= 1.15) {
      return _text('textScaleLarge');
    }
    return _text('textScaleDefault');
  }

  String themeLabel(AppThemePreferenceProxy preference) {
    return switch (preference) {
      AppThemePreferenceProxy.system => _text('themeSystem'),
      AppThemePreferenceProxy.light => _text('themeLight'),
      AppThemePreferenceProxy.dark => _text('themeDark'),
      AppThemePreferenceProxy.amoled => _text('themeAmoled'),
    };
  }

  String localeLabel(Locale locale) {
    final resolved = resolveLocale(locale);
    if (resolved == englishLocale) {
      return english;
    }
    if (resolved == simplifiedChineseLocale) {
      return simplifiedChinese;
    }
    return traditionalChinese;
  }

  String audioArchiveLabel(bool isWordArchive) {
    return isWordArchive ? audioWordArchive : audioSentenceArchive;
  }

  String downloadApproximateSize(String size) {
    return '${_text('downloadApproxPrefix')} $size';
  }

  String loadingAudio(String label) => '$loadingAudioPrefix $label';

  String playAudio(String label) => '$playAudioPrefix $label';

  String stopAudio(String label) => '$stopAudioPrefix $label';

  String downloadAudio(String label) {
    if (_languageTag == 'en') {
      return '$download $label';
    }
    return '$download$label';
  }

  String romanizationLabel(String value) =>
      _selectText('Romanization $value', '白话字 $value', '白話字 $value');

  String definitionLabel(String value) =>
      _selectText('Definition $value', '释义 $value', '釋義 $value');

  String mandarinLabel(String value) =>
      _selectText('Mandarin $value', '华语 $value', '華語 $value');

  String loadDataFailed(String error) => _selectText(
    'Failed to load data: $error',
    '资料载入失败：$error',
    '資料載入失敗：$error',
  );

  String linkedEntryNotFound(String word) =>
      _selectText('Entry not found: $word', '找不到词条：$word', '找不到詞條：$word');

  String dictionaryDatabaseRebuildFailed(String error) => _selectText(
    'Failed to rebuild dictionary database: $error',
    '重新构建词典资料库失败：$error',
    '重新構建詞典資料庫失敗：$error',
  );

  String dictionarySourcePaused(String fileName) => _selectText(
    'Paused downloading $fileName.',
    '已暂停下载 $fileName。',
    '已暫停下載 $fileName。',
  );

  String dictionarySourceDownloaded(String fileName) => _selectText(
    'Downloaded dictionary source file $fileName.',
    '已下载词典原始档 $fileName。',
    '已下載詞典原始檔 $fileName。',
  );

  String dictionarySourceDownloadFailed(String error) => _selectText(
    'Failed to download dictionary source file: $error',
    '下载词典原始档失败：$error',
    '下載詞典原始檔失敗：$error',
  );

  String dictionarySourceSheetMissing(String sheetName) => _selectText(
    'Missing worksheet in ODS: $sheetName',
    'ODS 内找不到工作表：$sheetName',
    'ODS 內找不到工作表：$sheetName',
  );

  String initializationDownloadProgress(String status, String speed) =>
      _selectText(
        'Downloaded $status at $speed',
        '已下载 $status，速度 $speed',
        '已下載 $status，速度 $speed',
      );

  String initializationParsingRows(int processed, int total) => _selectText(
    'Parsing row ${_formatInteger(processed)} of ${_formatInteger(total)}...',
    '正在解析第 ${_formatInteger(processed)} / ${_formatInteger(total)} 列…',
    '正在解析第 ${_formatInteger(processed)} / ${_formatInteger(total)} 列…',
  );

  String initializationWritingRows(int processed, int total) => _selectText(
    total > 0
        ? 'Writing ${_formatInteger(processed)} of ${_formatInteger(total)} records...'
        : 'Writing local database records...',
    total > 0
        ? '正在写入 ${_formatInteger(processed)} / ${_formatInteger(total)} 笔资料…'
        : '正在写入本机资料库…',
    total > 0
        ? '正在寫入 ${_formatInteger(processed)} / ${_formatInteger(total)} 筆資料…'
        : '正在寫入本機資料庫…',
  );

  String audioArchivePaused(String label) => _selectText(
    'Paused downloading $label.',
    '已暂停下载 $label。',
    '已暫停下載 $label。',
  );

  String audioArchiveUnexpectedFile(String fileName) => _selectText(
    'The downloaded file is not $fileName.',
    '下载回来的档案不是 $fileName',
    '下載回來的檔案不是 $fileName',
  );

  String audioArchiveDownloaded(String label) => _selectText(
    'Downloaded $label. It is now available offline.',
    '已下载 $label，之后可离线播放。',
    '已下載 $label，之後可離線播放。',
  );

  String redownloadConfirmationTitle(String label) => _selectText(
    'Confirm re-download of $label?',
    '确认要重新下载 $label？',
    '確認要重新下載 $label？',
  );

  String redownloadConfirmationBody(String size) => _selectText(
    'About $size. This may take some time. Are you sure you want to continue?',
    '大小约 $size，这将花费一些时间。您确定要继续吗？',
    '大小約 $size，這將花費一些時間。您確定要繼續嗎？',
  );

  String audioArchiveDownloadFailed(String label, String error) => _selectText(
    'Failed to download $label: $error',
    '下载 $label 失败：$error',
    '下載 $label 失敗：$error',
  );

  String audioArchiveDownloadFirst(String fileName) => _selectText(
    'Please download $fileName first.',
    '请先下载 $fileName。',
    '請先下載 $fileName。',
  );

  String audioClipNotFound(String clipId) => _selectText(
    'Audio clip not found: $clipId',
    '找不到音档：$clipId',
    '找不到音檔：$clipId',
  );

  String audioPlaybackFailed(String error) =>
      _selectText('Playback failed: $error', '播放失败：$error', '播放失敗：$error');

  String zipEntryNotStored(String fileName) => _selectText(
    'ZIP entry is not stored mode: $fileName',
    'zip 内的音档不是 stored 模式：$fileName',
    'zip 內的音檔不是 stored 模式：$fileName',
  );

  String linkedDefinitionWordLabel(String word) =>
      _selectText('Open linked entry $word', '开启关联词条 $word', '開啟關聯詞條 $word');

  String get searchThisWordHint =>
      _selectText('Double tap to search this word', '双击搜寻这个词', '雙擊搜尋這個詞');

  String get variantCharactersLabel =>
      _selectText('Variant Characters', '异用字', '異用字');

  String get synonymsLabel => _selectText('Synonyms', '近义', '近義');

  String get antonymsLabel => _selectText('Antonyms', '反义', '反義');

  String get alternativePronunciationLabel =>
      _selectText('Alternative Pronunciation', '又唸作', '又唸作');

  String get contractedPronunciationLabel =>
      _selectText('Contracted Pronunciation', '合音唸作', '合音唸作');

  String get colloquialPronunciationLabel =>
      _selectText('Colloquial Pronunciation', '俗唸作', '俗唸作');

  String get phoneticDifferencesLabel =>
      _selectText('Phonetic Differences', '语音差异', '語音差異');

  String get vocabularyComparisonLabel =>
      _selectText('Vocabulary Comparison', '词汇比较', '詞彙比較');

  String semanticsProgressValue(int downloadedBytes, int totalBytes) =>
      _selectText(
        totalBytes > 0
            ? '${(downloadedBytes / totalBytes * 100).round()} percent'
            : 'Progress unavailable',
        totalBytes > 0
            ? '已完成 ${(downloadedBytes / totalBytes * 100).round()}%'
            : '无法取得进度',
        totalBytes > 0
            ? '已完成 ${(downloadedBytes / totalBytes * 100).round()}%'
            : '無法取得進度',
      );

  String semanticsJoined(List<String> segments) {
    final filtered = segments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (filtered.isEmpty) {
      return '';
    }
    return _languageTag == 'en' ? filtered.join('. ') : filtered.join('。');
  }

  String _formatInteger(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

enum AppThemePreferenceProxy { system, light, dark, amoled }

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(
      AppLocalizations.resolveLocale(locale),
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
