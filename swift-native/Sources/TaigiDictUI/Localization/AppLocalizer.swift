import Foundation
import TaigiDictCore

public enum AppLocalizedStringKey: String, CaseIterable {
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
        let resolved = String(
            localized: String.LocalizationValue(key.rawValue),
            table: "Localizable",
            bundle: .module,
            locale: Locale(identifier: locale.rawValue)
        )

        assertionFailureIfMissing(resolved, key: key)
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

    private static func assertionFailureIfMissing(_ resolved: String, key: AppLocalizedStringKey) {
        guard resolved == key.rawValue else {
            return
        }

        assertionFailure("Missing localized resource for key \(key.rawValue)")
    }
}
