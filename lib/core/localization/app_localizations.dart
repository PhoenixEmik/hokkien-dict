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
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
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
      'bookmarksTitle': 'Bookmarks',
      'bookmarksEmptyTitle': 'No bookmarks yet',
      'bookmarksEmptyBody':
          'Bookmark a word from the detail page and it will appear here.',
      'settingsTitle': 'Settings',
      'offlineResources': 'Offline Resources',
      'appearance': 'Appearance',
      'about': 'About',
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
      'audioWordArchive': 'Word Audio',
      'audioSentenceArchive': 'Example Audio',
      'loadingAudioPrefix': 'Loading',
      'playAudioPrefix': 'Play',
      'stopAudioPrefix': 'Stop',
      'download': 'Download',
      'pause': 'Pause',
      'resume': 'Resume',
      'retry': 'Retry',
      'redownload': 'Re-download',
      'downloadReady': 'Downloaded and ready for offline playback',
      'downloadApproxPrefix': 'About',
      'tailoGuide': 'Tai-lo Orthography Guide',
      'tailoGuideSubtitle':
          'Read a summary of the ministry guide and Tai-lo spelling rules.',
      'hanjiGuide': 'Hanji Usage Principles',
      'hanjiGuideSubtitle':
          'Read a summary of the ministry guide and character selection rules.',
      'aboutApp': 'About Hokkien Dictionary',
      'aboutDescription':
          'Hokkien Dictionary provides offline bidirectional lookup between Taiwanese and Mandarin, with downloadable ministry audio for words and examples.',
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
      'bookmarksTitle': '书签',
      'bookmarksEmptyTitle': '尚未加入任何书签',
      'bookmarksEmptyBody': '从词条详细页点选书签图示，就会显示在这里。',
      'settingsTitle': '设置',
      'offlineResources': '离线资源',
      'appearance': '外观',
      'about': '关于',
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
      'audioWordArchive': '词目音档',
      'audioSentenceArchive': '例句音档',
      'loadingAudioPrefix': '正在载入',
      'playAudioPrefix': '播放',
      'stopAudioPrefix': '停止播放',
      'download': '下载',
      'pause': '暂停',
      'resume': '继续',
      'retry': '重试',
      'redownload': '重新下载',
      'downloadReady': '已下载，可离线播放',
      'downloadApproxPrefix': '大小约',
      'tailoGuide': '台罗标注说明',
      'tailoGuideSubtitle': '查看教育部页面的重点整理与台罗拼写原则。',
      'hanjiGuide': '汉字用字原则',
      'hanjiGuideSubtitle': '查看教育部页面的重点整理与辞典汉字选用方式。',
      'aboutApp': '关于台语辞典',
      'aboutDescription': '台语辞典提供离线的台语与华语双向查询，并支持下载教育部词目与例句音档。',
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
      'bookmarksTitle': '書籤',
      'bookmarksEmptyTitle': '尚未加入任何書籤',
      'bookmarksEmptyBody': '從詞條詳細頁點選書籤圖示，就會顯示在這裡。',
      'settingsTitle': '設定',
      'offlineResources': '離線資源',
      'appearance': '外觀',
      'about': '關於',
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
      'audioWordArchive': '詞目音檔',
      'audioSentenceArchive': '例句音檔',
      'loadingAudioPrefix': '正在載入',
      'playAudioPrefix': '播放',
      'stopAudioPrefix': '停止播放',
      'download': '下載',
      'pause': '暫停',
      'resume': '繼續',
      'retry': '重試',
      'redownload': '重新下載',
      'downloadReady': '已下載，可離線播放',
      'downloadApproxPrefix': '大小約',
      'tailoGuide': '臺羅標注說明',
      'tailoGuideSubtitle': '查看教育部頁面的重點整理與台羅拼寫原則。',
      'hanjiGuide': '漢字用字原則',
      'hanjiGuideSubtitle': '查看教育部頁面的重點整理與辭典漢字選用方式。',
      'aboutApp': '關於台語辭典',
      'aboutDescription': '台語辭典提供離線的台語與華語雙向查詢，並支援下載教育部詞目與例句音檔。',
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
  String get bookmarksTitle => _text('bookmarksTitle');
  String get bookmarksEmptyTitle => _text('bookmarksEmptyTitle');
  String get bookmarksEmptyBody => _text('bookmarksEmptyBody');
  String get settingsTitle => _text('settingsTitle');
  String get offlineResources => _text('offlineResources');
  String get appearance => _text('appearance');
  String get about => _text('about');
  String get languageSetting => _text('languageSetting');
  String get theme => _text('theme');
  String get displayMode => _text('displayMode');
  String get fontSize => _text('fontSize');
  String get small => _text('small');
  String get extraLarge => _text('extraLarge');
  String get audioWordArchive => _text('audioWordArchive');
  String get audioSentenceArchive => _text('audioSentenceArchive');
  String get loadingAudioPrefix => _text('loadingAudioPrefix');
  String get playAudioPrefix => _text('playAudioPrefix');
  String get stopAudioPrefix => _text('stopAudioPrefix');
  String get download => _text('download');
  String get pause => _text('pause');
  String get resume => _text('resume');
  String get retry => _text('retry');
  String get redownload => _text('redownload');
  String get downloadReady => _text('downloadReady');
  String get tailoGuide => _text('tailoGuide');
  String get tailoGuideSubtitle => _text('tailoGuideSubtitle');
  String get hanjiGuide => _text('hanjiGuide');
  String get hanjiGuideSubtitle => _text('hanjiGuideSubtitle');
  String get aboutApp => _text('aboutApp');
  String get aboutDescription => _text('aboutDescription');
  String get referencePage => _text('referencePage');
  String get shareEntry => _text('shareEntry');
  String get addBookmark => _text('addBookmark');
  String get removeBookmark => _text('removeBookmark');
  String get wordDetailFallbackTitle => _text('wordDetailFallbackTitle');
  String get english => _text('english');
  String get simplifiedChinese => _text('simplifiedChinese');
  String get traditionalChinese => _text('traditionalChinese');

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
