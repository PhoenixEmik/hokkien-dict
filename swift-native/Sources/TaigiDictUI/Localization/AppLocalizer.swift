import Foundation
import TaigiDictCore

public enum AppLocalizedStringKey: String {
    case tabDictionary
    case tabBookmarks
    case tabSettings
    case dictionaryTitle
    case searchPrompt
    case loadingDictionary
    case loadingFailedTitle
    case searching
    case noResultTitle
    case noResultDescription
    case searchResultsSection
    case searchStartTitle
    case searchStartDescription
    case searchHistoryTitle
    case clearSearchHistory
    case detailLoading
    case detailLoadFailedTitle
    case playWordAudio
    case playExampleAudio
    case audioSectionTitle
    case noAudioAvailable
    case audioNotInitialized
    case audioPlaying
    case audioStopped
    case audioPlaybackMissingClip
    case audioPlaybackArchiveBroken
    case audioPlaybackFailedPrefix
    case searchStartDetailTitle
    case searchStartDetailDescription
    case bookmarksAdd
    case bookmarksRemove
    case share
    case relationshipsVariant
    case relationshipsSynonym
    case relationshipsAntonym
    case definitionFallbackTitle
    case definitionSynonym
    case definitionAntonym

    case bookmarksTitle
    case bookmarksLoading
    case bookmarksEmptyTitle
    case bookmarksEmptyDescription
    case bookmarksSectionSaved

    case initializationFailedTitle
    case initializationRetry
    case initializationLoadingTitle
    case initializationLoadingDescription
    case initializationIncomplete

    case settingsTitle
    case settingsDisplayLanguageSection
    case settingsInterfaceLanguageLabel
    case settingsThemeLabel
    case settingsReadingTextScaleLabel
    case settingsDataAndInfoSection
    case settingsAdvanced
    case settingsAbout
    case settingsLicenses
    case settingsReferences
    case settingsDictionaryResourcesSection
    case settingsDictionarySource
    case dictionarySourceActionRestore
    case dictionarySourceActionDownload
    case settingsOfflineAudioSection
    case settingsWordAudio
    case settingsSentenceAudio
    case settingsActionsMenu
    case settingsClearConfirmTitle
    case settingsClearConfirmBody
    case commonDelete
    case commonCancel

    case audioStatusIdle
    case audioStatusDownloading
    case audioStatusPaused
    case audioStatusCompleted
    case audioStatusFailed
    case audioActionStart
    case audioActionPause
    case audioActionResume
    case audioActionRestart

    case localeTraditionalChinese
    case localeSimplifiedChinese
    case localeEnglish

    case themeSystem
    case themeLight
    case themeDark
    case themeAmoled

    case advancedTitle
    case advancedMaintenanceSection
    case advancedRebuild
    case advancedClear
    case advancedMaintenanceUnsupported
    case advancedSummarySection
    case advancedEntryCount
    case advancedSenseCount
    case advancedExampleCount
    case advancedSourceTimeSection
    case advancedBuiltAt
    case advancedSourceUpdated
    case advancedRunning
    case advancedStatusSection
    case advancedFailedTitle
    case advancedRebuildCompleted
    case advancedClearCompleted

    case aboutTitle
    case aboutAppSection
    case aboutAppDescription
    case aboutVersion
    case aboutVersionValue
    case aboutProjectSection
    case aboutGitHub
    case aboutPrivacy

    case licenseTitle
    case licenseSummarySection
    case licenseAppCode
    case licenseData
    case licenseAudio
    case licenseThirdParty
    case licenseViewThirdParty
    case licenseOverviewTitle
    case licenseOverviewCoreSection
    case licenseOverviewIOSSection
    case licenseOverviewAVFoundation

    case referenceTitle
    case referenceTaiLoTitle
    case referenceTaiLoP1
    case referenceTaiLoP2
    case referenceTaiLoB1
    case referenceTaiLoB2
    case referenceTaiLoB3
    case referenceHanjiTitle
    case referenceHanjiP1
    case referenceHanjiP2
    case referenceHanjiB1
    case referenceHanjiB2
    case referenceContentSection
    case referenceKeyPointsSection
    case referenceMappingSection
}

enum AppLocalizer {
    static func text(_ key: AppLocalizedStringKey, locale: AppLocale) -> String {
        if let resourceValue = resourceText(key, locale: locale) {
            return resourceValue
        }

        switch locale {
        case .traditionalChinese:
            return traditionalChinese(key)
        case .simplifiedChinese:
            return simplifiedChinese(key)
        case .english:
            return english(key)
        }
    }

    private static func resourceText(_ key: AppLocalizedStringKey, locale: AppLocale) -> String? {
        let resolved = String(
            localized: String.LocalizationValue(key.rawValue),
            table: "Localizable",
            bundle: .module,
            locale: Locale(identifier: locale.rawValue)
        )

        // String catalog lookup returns the key when not found; fallback to in-code tables in that case.
        guard resolved != key.rawValue else {
            return nil
        }

        return resolved
    }

    static func appLocale(from locale: Locale) -> AppLocale {
        let identifier = locale.identifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        if identifier.hasPrefix("zh-cn") || identifier.hasPrefix("zh-hans") {
            return .simplifiedChinese
        }
        if identifier.hasPrefix("zh") {
            return .traditionalChinese
        }
        return .english
    }

    private static func traditionalChinese(_ key: AppLocalizedStringKey) -> String {
        switch key {
        case .tabDictionary: return "辭典"
        case .tabBookmarks: return "書籤"
        case .tabSettings: return "設定"
        case .dictionaryTitle: return "辭典"
        case .searchPrompt: return "輸入台語漢字、白話字或華語詞義"
        case .loadingDictionary: return "載入辭典資料中"
        case .loadingFailedTitle: return "載入失敗"
        case .searching: return "搜尋中"
        case .noResultTitle: return "查無結果"
        case .noResultDescription: return "試試改用漢字、羅馬字或華語詞義。"
        case .searchResultsSection: return "搜尋結果"
        case .searchStartTitle: return "開始搜尋"
        case .searchStartDescription: return "輸入台語漢字、白話字，或華語釋義後才顯示詞條。"
        case .searchHistoryTitle: return "搜尋紀錄"
        case .clearSearchHistory: return "清除搜尋紀錄"
        case .detailLoading: return "準備詞條內容"
        case .detailLoadFailedTitle: return "詞條載入失敗"
        case .playWordAudio: return "播放詞目音檔"
        case .playExampleAudio: return "播放例句音檔"
        case .audioSectionTitle: return "音訊"
        case .noAudioAvailable: return "此筆資料沒有可播放的音檔。"
        case .audioNotInitialized: return "離線音訊尚未初始化。"
        case .audioPlaying: return "播放中"
        case .audioStopped: return "已停止播放"
        case .audioPlaybackMissingClip: return "播放失敗：找不到離線音檔。請先在設定下載或重新下載離線音訊資源。"
        case .audioPlaybackArchiveBroken: return "播放失敗：離線音訊檔案已損毀。請在設定重新下載離線音訊資源。"
        case .audioPlaybackFailedPrefix: return "播放失敗："
        case .searchStartDetailTitle: return "開始搜尋"
        case .searchStartDetailDescription: return "選擇搜尋結果後，詞條內容會顯示在這裡。"
        case .bookmarksAdd: return "加入書籤"
        case .bookmarksRemove: return "移除書籤"
        case .share: return "分享"
        case .relationshipsVariant: return "異用字"
        case .relationshipsSynonym: return "近義詞"
        case .relationshipsAntonym: return "反義詞"
        case .definitionFallbackTitle: return "解說"
        case .definitionSynonym: return "近義"
        case .definitionAntonym: return "反義"

        case .bookmarksTitle: return "書籤"
        case .bookmarksLoading: return "載入書籤中"
        case .bookmarksEmptyTitle: return "尚無書籤"
        case .bookmarksEmptyDescription: return "在詞條頁按下書籤按鈕後，會顯示在這裡。"
        case .bookmarksSectionSaved: return "已收藏詞條"

        case .initializationFailedTitle: return "初始化失敗"
        case .initializationRetry: return "重試"
        case .initializationLoadingTitle: return "載入中"
        case .initializationLoadingDescription: return "正在初始化辭典資料"
        case .initializationIncomplete: return "辭典初始化流程未完成。"

        case .settingsTitle: return "設定"
        case .settingsDisplayLanguageSection: return "顯示與語言"
        case .settingsInterfaceLanguageLabel: return "介面語言"
        case .settingsThemeLabel: return "主題"
        case .settingsReadingTextScaleLabel: return "閱讀字級"
        case .settingsDataAndInfoSection: return "資料與說明"
        case .settingsAdvanced: return "進階設定"
        case .settingsAbout: return "關於"
        case .settingsLicenses: return "授權資訊"
        case .settingsReferences: return "參考資料"
        case .settingsDictionaryResourcesSection: return "離線辭典資源"
        case .settingsDictionarySource: return "辭典來源資料"
        case .dictionarySourceActionRestore: return "從 App 還原"
        case .dictionarySourceActionDownload: return "下載最新版"
        case .settingsOfflineAudioSection: return "離線音訊資源"
        case .settingsWordAudio: return "詞目音檔"
        case .settingsSentenceAudio: return "例句音檔"
        case .settingsActionsMenu: return "操作"
        case .settingsClearConfirmTitle: return "確定要清除本機辭典資料？"
        case .settingsClearConfirmBody: return "清除後會移除本機資料，下次使用前會重新初始化。"
        case .commonDelete: return "清除"
        case .commonCancel: return "取消"

        case .audioStatusIdle: return "尚未下載"
        case .audioStatusDownloading: return "下載中"
        case .audioStatusPaused: return "已暫停"
        case .audioStatusCompleted: return "已完成"
        case .audioStatusFailed: return "失敗"
        case .audioActionStart: return "下載"
        case .audioActionPause: return "暫停"
        case .audioActionResume: return "續傳"
        case .audioActionRestart: return "重下載"

        case .localeTraditionalChinese: return "正體中文"
        case .localeSimplifiedChinese: return "简体中文"
        case .localeEnglish: return "English"

        case .themeSystem: return "跟隨系統"
        case .themeLight: return "淺色"
        case .themeDark: return "深色"
        case .themeAmoled: return "AMOLED"

        case .advancedTitle: return "進階設定"
        case .advancedMaintenanceSection: return "資料維護"
        case .advancedRebuild: return "重建本機辭典資料"
        case .advancedClear: return "清除本機辭典資料"
        case .advancedMaintenanceUnsupported: return "目前資料來源不支援本機維護操作。"
        case .advancedSummarySection: return "目前資料庫摘要"
        case .advancedEntryCount: return "詞目數"
        case .advancedSenseCount: return "義項數"
        case .advancedExampleCount: return "例句數"
        case .advancedSourceTimeSection: return "資料來源時間"
        case .advancedBuiltAt: return "建置時間"
        case .advancedSourceUpdated: return "來源更新"
        case .advancedRunning: return "資料維護作業進行中"
        case .advancedStatusSection: return "狀態"
        case .advancedFailedTitle: return "作業失敗"
        case .advancedRebuildCompleted: return "本機辭典資料已重建。"
        case .advancedClearCompleted: return "本機辭典資料已清除。"

        case .aboutTitle: return "關於"
        case .aboutAppSection: return "台語辭典"
        case .aboutAppDescription: return "台語辭典是離線優先的台語查詢工具，提供詞目、義項與例句檢索。"
        case .aboutVersion: return "版本"
        case .aboutVersionValue: return "Swift Native Preview"
        case .aboutProjectSection: return "專案"
        case .aboutGitHub: return "GitHub Repository"
        case .aboutPrivacy: return "隱私政策"

        case .licenseTitle: return "授權資訊"
        case .licenseSummarySection: return "授權摘要"
        case .licenseAppCode: return "App 程式碼：MIT License"
        case .licenseData: return "辭典資料：教育部授權條款"
        case .licenseAudio: return "音訊資源：來源授權條款"
        case .licenseThirdParty: return "第三方套件：各自授權"
        case .licenseViewThirdParty: return "查看第三方套件授權清單"
        case .licenseOverviewTitle: return "套件授權清單"
        case .licenseOverviewCoreSection: return "核心套件"
        case .licenseOverviewIOSSection: return "iOS 原生框架"
        case .licenseOverviewAVFoundation: return "AVFoundation (音訊功能預留)"

        case .referenceTitle: return "參考資料"
        case .referenceTaiLoTitle: return "臺羅標注說明"
        case .referenceTaiLoP1: return "臺羅是台語常見拼寫系統，重點在聲調與音節分界。"
        case .referenceTaiLoP2: return "搜尋時可輸入有調或無調格式，系統會做正規化處理。"
        case .referenceTaiLoB1: return "可使用連字號分隔音節"
        case .referenceTaiLoB2: return "大小寫不影響搜尋"
        case .referenceTaiLoB3: return "數字調號會在搜尋正規化中處理"
        case .referenceHanjiTitle: return "漢字用字原則"
        case .referenceHanjiP1: return "辭典內容以教育部資料來源為準。"
        case .referenceHanjiP2: return "同音異字、異用字會在詞條中提供對照。"
        case .referenceHanjiB1: return "優先採用主流教育體系常見用字"
        case .referenceHanjiB2: return "異體與俗字會在詞條標示"
        case .referenceContentSection: return "內文"
        case .referenceKeyPointsSection: return "重點"
        case .referenceMappingSection: return "對照"
        }
    }

    private static func simplifiedChinese(_ key: AppLocalizedStringKey) -> String {
        switch key {
        case .tabDictionary: return "辞典"
        case .tabBookmarks: return "书签"
        case .tabSettings: return "设置"
        case .dictionaryTitle: return "辞典"
        case .searchPrompt: return "输入台语汉字、白话字或华语词义"
        case .loadingDictionary: return "加载辞典资料中"
        case .loadingFailedTitle: return "加载失败"
        case .searching: return "搜索中"
        case .noResultTitle: return "查无结果"
        case .noResultDescription: return "试试改用汉字、罗马字或华语词义。"
        case .searchResultsSection: return "搜索结果"
        case .searchStartTitle: return "开始搜索"
        case .searchStartDescription: return "输入台语汉字、白话字，或华语释义后才显示词条。"
        case .searchHistoryTitle: return "搜索纪录"
        case .clearSearchHistory: return "清除搜索纪录"
        case .detailLoading: return "准备词条内容"
        case .detailLoadFailedTitle: return "词条载入失败"
        case .playWordAudio: return "播放词目音档"
        case .playExampleAudio: return "播放例句音档"
        case .audioSectionTitle: return "音讯"
        case .noAudioAvailable: return "此笔资料没有可播放的音档。"
        case .audioNotInitialized: return "离线音讯尚未初始化。"
        case .audioPlaying: return "播放中"
        case .audioStopped: return "已停止播放"
        case .audioPlaybackMissingClip: return "播放失败：找不到离线音档。请先在设置下载或重新下载离线音讯资源。"
        case .audioPlaybackArchiveBroken: return "播放失败：离线音讯档案已损毁。请在设置重新下载离线音讯资源。"
        case .audioPlaybackFailedPrefix: return "播放失败："
        case .searchStartDetailTitle: return "开始搜索"
        case .searchStartDetailDescription: return "选择搜索结果后，词条内容会显示在这里。"
        case .bookmarksAdd: return "加入书签"
        case .bookmarksRemove: return "移除书签"
        case .share: return "分享"
        case .relationshipsVariant: return "异用字"
        case .relationshipsSynonym: return "近义词"
        case .relationshipsAntonym: return "反义词"
        case .definitionFallbackTitle: return "解说"
        case .definitionSynonym: return "近义"
        case .definitionAntonym: return "反义"

        case .bookmarksTitle: return "书签"
        case .bookmarksLoading: return "载入书签中"
        case .bookmarksEmptyTitle: return "尚无书签"
        case .bookmarksEmptyDescription: return "在词条页按下书签按钮后，会显示在这里。"
        case .bookmarksSectionSaved: return "已收藏词条"

        case .initializationFailedTitle: return "初始化失败"
        case .initializationRetry: return "重试"
        case .initializationLoadingTitle: return "载入中"
        case .initializationLoadingDescription: return "正在初始化辞典资料"
        case .initializationIncomplete: return "辞典初始化流程未完成。"

        case .settingsTitle: return "设置"
        case .settingsDisplayLanguageSection: return "显示与语言"
        case .settingsInterfaceLanguageLabel: return "界面语言"
        case .settingsThemeLabel: return "主题"
        case .settingsReadingTextScaleLabel: return "阅读字级"
        case .settingsDataAndInfoSection: return "资料与说明"
        case .settingsAdvanced: return "进阶设置"
        case .settingsAbout: return "关于"
        case .settingsLicenses: return "授权资讯"
        case .settingsReferences: return "参考资料"
        case .settingsDictionaryResourcesSection: return "离线辞典资源"
        case .settingsDictionarySource: return "辞典来源资料"
        case .dictionarySourceActionRestore: return "从 App 还原"
        case .dictionarySourceActionDownload: return "下载最新版"
        case .settingsOfflineAudioSection: return "离线音讯资源"
        case .settingsWordAudio: return "词目音档"
        case .settingsSentenceAudio: return "例句音档"
        case .settingsActionsMenu: return "操作"
        case .settingsClearConfirmTitle: return "确定要清除本机辞典资料？"
        case .settingsClearConfirmBody: return "清除后会移除本机资料，下次使用前会重新初始化。"
        case .commonDelete: return "清除"
        case .commonCancel: return "取消"

        case .audioStatusIdle: return "尚未下载"
        case .audioStatusDownloading: return "下载中"
        case .audioStatusPaused: return "已暂停"
        case .audioStatusCompleted: return "已完成"
        case .audioStatusFailed: return "失败"
        case .audioActionStart: return "下载"
        case .audioActionPause: return "暂停"
        case .audioActionResume: return "续传"
        case .audioActionRestart: return "重下载"

        case .localeTraditionalChinese: return "正体中文"
        case .localeSimplifiedChinese: return "简体中文"
        case .localeEnglish: return "English"

        case .themeSystem: return "跟随系统"
        case .themeLight: return "浅色"
        case .themeDark: return "深色"
        case .themeAmoled: return "AMOLED"

        case .advancedTitle: return "进阶设置"
        case .advancedMaintenanceSection: return "资料维护"
        case .advancedRebuild: return "重建本机辞典资料"
        case .advancedClear: return "清除本机辞典资料"
        case .advancedMaintenanceUnsupported: return "目前资料来源不支持本机维护操作。"
        case .advancedSummarySection: return "目前资料库摘要"
        case .advancedEntryCount: return "词目数"
        case .advancedSenseCount: return "义项数"
        case .advancedExampleCount: return "例句数"
        case .advancedSourceTimeSection: return "资料来源时间"
        case .advancedBuiltAt: return "建置时间"
        case .advancedSourceUpdated: return "来源更新"
        case .advancedRunning: return "资料维护作业进行中"
        case .advancedStatusSection: return "状态"
        case .advancedFailedTitle: return "作业失败"
        case .advancedRebuildCompleted: return "本机辞典资料已重建。"
        case .advancedClearCompleted: return "本机辞典资料已清除。"

        case .aboutTitle: return "关于"
        case .aboutAppSection: return "台语辞典"
        case .aboutAppDescription: return "台语辞典是离线优先的台语查询工具，提供词目、义项与例句检索。"
        case .aboutVersion: return "版本"
        case .aboutVersionValue: return "Swift Native Preview"
        case .aboutProjectSection: return "项目"
        case .aboutGitHub: return "GitHub Repository"
        case .aboutPrivacy: return "隐私政策"

        case .licenseTitle: return "授权资讯"
        case .licenseSummarySection: return "授权摘要"
        case .licenseAppCode: return "App 程序码：MIT License"
        case .licenseData: return "辞典资料：教育部授权条款"
        case .licenseAudio: return "音讯资源：来源授权条款"
        case .licenseThirdParty: return "第三方套件：各自授权"
        case .licenseViewThirdParty: return "查看第三方套件授权清单"
        case .licenseOverviewTitle: return "套件授权清单"
        case .licenseOverviewCoreSection: return "核心套件"
        case .licenseOverviewIOSSection: return "iOS 原生框架"
        case .licenseOverviewAVFoundation: return "AVFoundation (音讯功能预留)"

        case .referenceTitle: return "参考资料"
        case .referenceTaiLoTitle: return "台罗标注说明"
        case .referenceTaiLoP1: return "台罗是台语常见拼写系统，重点在声调与音节分界。"
        case .referenceTaiLoP2: return "搜索时可输入有调或无调格式，系统会做正规化处理。"
        case .referenceTaiLoB1: return "可使用连字号分隔音节"
        case .referenceTaiLoB2: return "大小写不影响搜索"
        case .referenceTaiLoB3: return "数字调号会在搜索正规化中处理"
        case .referenceHanjiTitle: return "汉字用字原则"
        case .referenceHanjiP1: return "辞典内容以教育部资料来源为准。"
        case .referenceHanjiP2: return "同音异字、异用字会在词条中提供对照。"
        case .referenceHanjiB1: return "优先采用主流教育体系常见用字"
        case .referenceHanjiB2: return "异体与俗字会在词条标示"
        case .referenceContentSection: return "内文"
        case .referenceKeyPointsSection: return "重点"
        case .referenceMappingSection: return "对照"
        }
    }

    private static func english(_ key: AppLocalizedStringKey) -> String {
        switch key {
        case .tabDictionary: return "Dictionary"
        case .tabBookmarks: return "Bookmarks"
        case .tabSettings: return "Settings"
        case .dictionaryTitle: return "Dictionary"
        case .searchPrompt: return "Search Taiwanese Hanji, romanization, or Mandarin meaning"
        case .loadingDictionary: return "Loading dictionary"
        case .loadingFailedTitle: return "Load failed"
        case .searching: return "Searching"
        case .noResultTitle: return "No results"
        case .noResultDescription: return "Try Hanji, romanization, or Mandarin meanings."
        case .searchResultsSection: return "Results"
        case .searchStartTitle: return "Start searching"
        case .searchStartDescription: return "Type Hanji, romanization, or Mandarin meaning to see entries."
        case .searchHistoryTitle: return "Search history"
        case .clearSearchHistory: return "Clear search history"
        case .detailLoading: return "Preparing entry"
        case .detailLoadFailedTitle: return "Failed to load entry"
        case .playWordAudio: return "Play word audio"
        case .playExampleAudio: return "Play example audio"
        case .audioSectionTitle: return "Audio"
        case .noAudioAvailable: return "No playable audio for this item."
        case .audioNotInitialized: return "Offline audio is not initialized yet."
        case .audioPlaying: return "Playing"
        case .audioStopped: return "Stopped"
        case .audioPlaybackMissingClip: return "Playback failed: Offline audio clip is missing. Please download or re-download offline audio in Settings."
        case .audioPlaybackArchiveBroken: return "Playback failed: Offline audio archive is corrupted. Please re-download offline audio in Settings."
        case .audioPlaybackFailedPrefix: return "Playback failed: "
        case .searchStartDetailTitle: return "Start searching"
        case .searchStartDetailDescription: return "Select a search result to view details here."
        case .bookmarksAdd: return "Add bookmark"
        case .bookmarksRemove: return "Remove bookmark"
        case .share: return "Share"
        case .relationshipsVariant: return "Variants"
        case .relationshipsSynonym: return "Synonyms"
        case .relationshipsAntonym: return "Antonyms"
        case .definitionFallbackTitle: return "Definition"
        case .definitionSynonym: return "Synonyms"
        case .definitionAntonym: return "Antonyms"

        case .bookmarksTitle: return "Bookmarks"
        case .bookmarksLoading: return "Loading bookmarks"
        case .bookmarksEmptyTitle: return "No bookmarks yet"
        case .bookmarksEmptyDescription: return "Bookmarked entries will appear here."
        case .bookmarksSectionSaved: return "Saved entries"

        case .initializationFailedTitle: return "Initialization failed"
        case .initializationRetry: return "Retry"
        case .initializationLoadingTitle: return "Loading"
        case .initializationLoadingDescription: return "Initializing dictionary data"
        case .initializationIncomplete: return "Dictionary initialization did not complete."

        case .settingsTitle: return "Settings"
        case .settingsDisplayLanguageSection: return "Display and language"
        case .settingsInterfaceLanguageLabel: return "Interface language"
        case .settingsThemeLabel: return "Theme"
        case .settingsReadingTextScaleLabel: return "Reading text scale"
        case .settingsDataAndInfoSection: return "Data and info"
        case .settingsAdvanced: return "Advanced settings"
        case .settingsAbout: return "About"
        case .settingsLicenses: return "License info"
        case .settingsReferences: return "References"
        case .settingsDictionaryResourcesSection: return "Offline dictionary resources"
        case .settingsDictionarySource: return "Dictionary source data"
        case .dictionarySourceActionRestore: return "Restore from app"
        case .dictionarySourceActionDownload: return "Download latest"
        case .settingsOfflineAudioSection: return "Offline audio resources"
        case .settingsWordAudio: return "Word audio"
        case .settingsSentenceAudio: return "Sentence audio"
        case .settingsActionsMenu: return "Actions"
        case .settingsClearConfirmTitle: return "Clear local dictionary data?"
        case .settingsClearConfirmBody: return "This removes local data and initialization will run again next launch."
        case .commonDelete: return "Delete"
        case .commonCancel: return "Cancel"

        case .audioStatusIdle: return "Not downloaded"
        case .audioStatusDownloading: return "Downloading"
        case .audioStatusPaused: return "Paused"
        case .audioStatusCompleted: return "Completed"
        case .audioStatusFailed: return "Failed"
        case .audioActionStart: return "Download"
        case .audioActionPause: return "Pause"
        case .audioActionResume: return "Resume"
        case .audioActionRestart: return "Restart"

        case .localeTraditionalChinese: return "Traditional Chinese"
        case .localeSimplifiedChinese: return "Simplified Chinese"
        case .localeEnglish: return "English"

        case .themeSystem: return "System"
        case .themeLight: return "Light"
        case .themeDark: return "Dark"
        case .themeAmoled: return "AMOLED"

        case .advancedTitle: return "Advanced settings"
        case .advancedMaintenanceSection: return "Data maintenance"
        case .advancedRebuild: return "Rebuild local dictionary data"
        case .advancedClear: return "Clear local dictionary data"
        case .advancedMaintenanceUnsupported: return "Current data source does not support local maintenance."
        case .advancedSummarySection: return "Current database summary"
        case .advancedEntryCount: return "Entries"
        case .advancedSenseCount: return "Senses"
        case .advancedExampleCount: return "Examples"
        case .advancedSourceTimeSection: return "Source timestamps"
        case .advancedBuiltAt: return "Built at"
        case .advancedSourceUpdated: return "Source updated"
        case .advancedRunning: return "Maintenance in progress"
        case .advancedStatusSection: return "Status"
        case .advancedFailedTitle: return "Action failed"
        case .advancedRebuildCompleted: return "Local dictionary data rebuilt."
        case .advancedClearCompleted: return "Local dictionary data cleared."

        case .aboutTitle: return "About"
        case .aboutAppSection: return "Taigi Dictionary"
        case .aboutAppDescription: return "Taigi Dictionary is an offline-first Taiwanese search tool with entries, senses, and examples."
        case .aboutVersion: return "Version"
        case .aboutVersionValue: return "Swift Native Preview"
        case .aboutProjectSection: return "Project"
        case .aboutGitHub: return "GitHub Repository"
        case .aboutPrivacy: return "Privacy policy"

        case .licenseTitle: return "License info"
        case .licenseSummarySection: return "License summary"
        case .licenseAppCode: return "App code: MIT License"
        case .licenseData: return "Dictionary data: MOE terms"
        case .licenseAudio: return "Audio resources: source terms"
        case .licenseThirdParty: return "Third-party packages: respective licenses"
        case .licenseViewThirdParty: return "View third-party license list"
        case .licenseOverviewTitle: return "Package license list"
        case .licenseOverviewCoreSection: return "Core packages"
        case .licenseOverviewIOSSection: return "iOS native frameworks"
        case .licenseOverviewAVFoundation: return "AVFoundation (reserved for audio)"

        case .referenceTitle: return "References"
        case .referenceTaiLoTitle: return "Tai-Lo notation"
        case .referenceTaiLoP1: return "Tai-Lo is a common Taiwanese romanization system focused on tones and syllable boundaries."
        case .referenceTaiLoP2: return "Search accepts both tone-marked and plain forms and applies normalization."
        case .referenceTaiLoB1: return "Use hyphens to split syllables"
        case .referenceTaiLoB2: return "Search is case-insensitive"
        case .referenceTaiLoB3: return "Numeric tone marks are normalized in search"
        case .referenceHanjiTitle: return "Hanji usage principles"
        case .referenceHanjiP1: return "Dictionary content follows Ministry of Education source data."
        case .referenceHanjiP2: return "Homophones and variants are cross-referenced in entries."
        case .referenceHanjiB1: return "Prefer commonly used educational forms"
        case .referenceHanjiB2: return "Variant and colloquial forms are marked"
        case .referenceContentSection: return "Content"
        case .referenceKeyPointsSection: return "Key points"
        case .referenceMappingSection: return "Mapping"
        }
    }
}
