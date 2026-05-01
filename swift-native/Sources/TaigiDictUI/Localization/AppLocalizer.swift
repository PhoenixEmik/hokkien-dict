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
    case detailLoadFailedTitle
    case detailAlternativePronunciationsTitle
    case detailContractedPronunciationsTitle
    case detailColloquialPronunciationsTitle
    case detailPhoneticDifferencesTitle
    case detailVocabularyComparisonsTitle
    case detailLinkedReferenceFormat
    case playWordAudio
    case playExampleAudio
    case audioPlaybackAlertTitle
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
    case settingsReadingTextScaleValueFormat
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
    case commonOK

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
    case localeSystem

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
    case aboutAuthor
    case aboutVersion
    case aboutVersionValue
    case aboutProjectSection
    case aboutGitHub
    case aboutRepositorySubtitle
    case aboutLicensesSubtitle
    case aboutPrivacy
    case aboutPrivacySubtitle
    case aboutReferencePage

    case licenseTitle
    case licenseSummarySection
    case licenseAppCode
    case licenseAppCodeDescription
    case licenseData
    case licenseDataDescription
    case licenseAudio
    case licenseAudioDescription
    case licenseMinistryCopyright
    case licenseThirdParty
    case licenseViewThirdParty
    case licenseOverviewTitle
    case licenseOverviewCoreSection
    case licenseOverviewIOSSection
    case licenseOverviewAVFoundation

    case referenceTitle
    case referenceTaiLoTitle
    case referenceTaiLoSectionGeneralTones
    case referenceTaiLoSectionSpecialTones
    case referenceTaiLoSectionToneSandhi
    case referenceTaiLoSectionNeutralTone
    case referenceTaiLoP1
    case referenceTaiLoP2
    case referenceTaiLoB1
    case referenceTaiLoB2
    case referenceTaiLoB3
    case referenceTaiLoB4
    case referenceTaiLoB5
    case referenceTaiLoB6
    case referenceTaiLoToneRow1Value
    case referenceTaiLoToneRow2Value
    case referenceTaiLoSandhiRow1Value
    case referenceTaiLoSandhiRow2Value
    case referenceTaiLoSandhiRow3Value
    case referenceTaiLoSandhiRow4Value
    case referenceTaiLoNeutralExample1
    case referenceTaiLoNeutralExample2
    case referenceTaiLoNeutralExample3
    case referenceHanjiTitle
    case referenceHanjiSectionOverview
    case referenceHanjiSectionTypes
    case referenceHanjiSectionSubstitute
    case referenceHanjiSectionRecommended
    case referenceHanjiP1
    case referenceHanjiP2
    case referenceHanjiB1
    case referenceHanjiB2
    case referenceHanjiB3
    case referenceHanjiB4
    case referenceHanjiB5
    case referenceHanjiSubstituteRow1Value
    case referenceHanjiSubstituteRow2Value
    case referenceHanjiSubstituteRow3Value
    case referenceHanjiRecommendedP1
    case referenceContentSection
    case referenceKeyPointsSection
    case referenceMappingSection
}

enum AppLocalizer {
    private static let configurationLock = NSLock()
    private static var configuration = LocalizationConfiguration(
        language: .system,
        systemLocale: .autoupdatingCurrent
    )

    static func configure(language: AppLanguage, systemLocale: Locale) {
        configurationLock.lock()
        configuration = LocalizationConfiguration(language: language, systemLocale: systemLocale)
        configurationLock.unlock()
    }

    static func text(_ key: AppLocalizedStringKey, locale: AppLocale) -> String {
        let configuration = currentConfiguration()
        return text(
            key,
            language: configuration.language,
            systemLocale: configuration.systemLocale,
            localeOverride: locale
        )
    }

    static func text(
        _ key: AppLocalizedStringKey,
        language: AppLanguage,
        systemLocale: Locale,
        localeOverride: AppLocale? = nil
    ) -> String {
        let resolvedLocale = localeOverride ?? language.resolvedAppLocale(systemLocale: systemLocale)
        let bundle = localizedBundle(for: language, systemLocale: systemLocale)
        let resolved = bundle.localizedString(forKey: key.rawValue, value: nil, table: "Localizable")

        if resolved == key.rawValue, let catalogValue = resourceCatalog.text(key.rawValue, locale: resolvedLocale) {
            return catalogValue
        }

        assertionFailureIfMissing(resolved, key: key)
        return resolved
    }

    static func formattedText(_ key: AppLocalizedStringKey, locale: AppLocale, _ arguments: CVarArg...) -> String {
        let configuration = currentConfiguration()
        return formattedText(
            key,
            language: configuration.language,
            systemLocale: configuration.systemLocale,
            localeOverride: locale,
            arguments: arguments
        )
    }

    static func formattedText(
        _ key: AppLocalizedStringKey,
        language: AppLanguage,
        systemLocale: Locale,
        localeOverride: AppLocale? = nil,
        arguments: [CVarArg]
    ) -> String {
        let resolvedLocale = localeOverride ?? language.resolvedAppLocale(systemLocale: systemLocale)
        return String(
            format: text(key, language: language, systemLocale: systemLocale, localeOverride: localeOverride),
            locale: Locale(identifier: resolvedLocale.rawValue),
            arguments: arguments
        )
    }

    private static let resourceCatalog = LocalizedStringCatalog(bundle: .module)

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

    private static func currentConfiguration() -> LocalizationConfiguration {
        configurationLock.lock()
        let configuration = configuration
        configurationLock.unlock()
        return configuration
    }

    private static func localizedBundle(for language: AppLanguage, systemLocale: Locale) -> Bundle {
        let localizationIdentifier = switch language {
        case .system:
            language.resolvedAppLocale(systemLocale: systemLocale).localizationIdentifier
        case .zhHant, .zhHans, .en:
            language.localizationIdentifier
        }

        guard
            let localizationIdentifier,
            let url = Bundle.module.url(forResource: localizationIdentifier, withExtension: "lproj"),
            let bundle = Bundle(url: url)
        else {
            return .module
        }

        return bundle
    }

    private static func assertionFailureIfMissing(_ resolved: String, key: AppLocalizedStringKey) {
        guard resolved == key.rawValue else {
            return
        }

        assertionFailure("Missing localized resource for key \(key.rawValue)")
    }
}

private struct LocalizationConfiguration {
    var language: AppLanguage
    var systemLocale: Locale
}

private struct LocalizedStringCatalog {
    private let strings: [String: CatalogEntry]

    init(bundle: Bundle) {
        guard
            let url = bundle.url(forResource: "Localizable", withExtension: "xcstrings"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
        else {
            strings = [:]
            return
        }

        strings = catalog.strings
    }

    func text(_ key: String, locale: AppLocale) -> String? {
        let preferredLanguage = switch locale {
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        case .traditionalChinese:
            "zh-Hant"
        }

        return strings[key]?.localizations?[preferredLanguage]?.stringUnit?.value
    }

    private struct Catalog: Decodable {
        var strings: [String: CatalogEntry]
    }

    private struct CatalogEntry: Decodable {
        var localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        var stringUnit: StringUnit?
    }

    private struct StringUnit: Decodable {
        var value: String
    }
}

private extension AppLocale {
    var localizationIdentifier: String {
        switch self {
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        case .traditionalChinese:
            return "zh-Hant"
        }
    }
}
