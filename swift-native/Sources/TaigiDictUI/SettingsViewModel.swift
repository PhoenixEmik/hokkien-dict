import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class SettingsViewModel {
    public enum MaintenanceAction {
        case rebuild
        case clear
    }

    public private(set) var supportsDataMaintenance = false
    public private(set) var isRunningAction = false
    public private(set) var statusMessage: String?
    public private(set) var errorMessage: String?
    public private(set) var selectedLocale: AppLocale = .traditionalChinese
    public private(set) var selectedThemePreference: AppThemePreference = .system
    public private(set) var readingTextScale = 1.0
    public private(set) var librarySummary: DictionaryLibrarySummary?
    public private(set) var libraryMetadata: DictionaryLibraryMetadata?
    public private(set) var metadataBuiltAtDisplay: String?
    public private(set) var metadataSourceModifiedAtDisplay: String?
    public private(set) var isClearConfirmationPresented = false

    private let library: DictionaryLibrary
    private let dateFormatter: any SettingsDateFormatting
    private let settingsStore: any AppSettingsStoring

    public init(
        library: DictionaryLibrary,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        dateFormatter: any SettingsDateFormatting = SettingsDateFormatter()
    ) {
        self.library = library
        self.settingsStore = settingsStore
        self.dateFormatter = dateFormatter
    }

    public var minReadingTextScale: Double {
        AppSettingsSnapshot.minReadingTextScale
    }

    public var maxReadingTextScale: Double {
        AppSettingsSnapshot.maxReadingTextScale
    }

    public var readingTextScaleDivisions: Int {
        AppSettingsSnapshot.readingTextScaleDivisions
    }

    public var currentSettingsSnapshot: AppSettingsSnapshot {
        AppSettingsSnapshot(
            interfaceLocale: selectedLocale,
            themePreference: selectedThemePreference,
            readingTextScale: readingTextScale
        )
    }

    public func loadCapabilities() async {
        errorMessage = nil
        let settings = await settingsStore.load()
        selectedLocale = settings.interfaceLocale
        selectedThemePreference = settings.themePreference
        readingTextScale = settings.readingTextScale

        supportsDataMaintenance = await library.supportsLocalMaintenance()
        librarySummary = await library.currentSummary()
        libraryMetadata = try? await library.metadata()
        refreshMetadataDisplay()

        if librarySummary == nil {
            let phase = await library.prepare()
            switch phase {
            case .ready(let summary):
                librarySummary = summary
                libraryMetadata = try? await library.metadata()
                refreshMetadataDisplay()
            case .failed(let message):
                errorMessage = message
            case .idle, .loading:
                break
            }
        }
    }

    public func setLocale(_ locale: AppLocale) async {
        guard selectedLocale != locale else {
            return
        }

        selectedLocale = locale
        await settingsStore.setInterfaceLocale(locale)
    }

    public func setThemePreference(_ preference: AppThemePreference) async {
        guard selectedThemePreference != preference else {
            return
        }

        selectedThemePreference = preference
        await settingsStore.setThemePreference(preference)
    }

    public func setReadingTextScale(_ value: Double) async {
        let snapped = AppSettingsSnapshot.snapReadingTextScale(value)
        guard readingTextScale != snapped else {
            return
        }

        readingTextScale = snapped
        await settingsStore.setReadingTextScale(snapped)
    }

    public func requestClearConfirmation() {
        guard supportsDataMaintenance, !isRunningAction else {
            return
        }
        isClearConfirmationPresented = true
    }

    public func cancelClearConfirmation() {
        isClearConfirmationPresented = false
    }

    @discardableResult
    public func confirmClear() async -> Bool {
        isClearConfirmationPresented = false
        return await run(.clear)
    }

    @discardableResult
    public func run(_ action: MaintenanceAction) async -> Bool {
        guard !isRunningAction else {
            return false
        }

        isClearConfirmationPresented = false
        isRunningAction = true
        errorMessage = nil

        do {
            switch action {
            case .rebuild:
                try await library.rebuildInstalledDatabase()
                statusMessage = "本機辭典資料已重建。"
                let phase = await library.prepare()
                if case let .ready(summary) = phase {
                    librarySummary = summary
                }
                libraryMetadata = try? await library.metadata()
                refreshMetadataDisplay()
            case .clear:
                try await library.clearInstalledDatabase()
                statusMessage = "本機辭典資料已清除。"
                librarySummary = nil
                libraryMetadata = nil
                refreshMetadataDisplay()
            }
            isRunningAction = false
            return true
        } catch {
            errorMessage = String(describing: error)
            statusMessage = nil
            isRunningAction = false
            return false
        }
    }

    private func refreshMetadataDisplay() {
        metadataBuiltAtDisplay = dateFormatter.displayString(from: libraryMetadata?.builtAt)
        metadataSourceModifiedAtDisplay = dateFormatter.displayString(from: libraryMetadata?.sourceModifiedAt)
    }
}
