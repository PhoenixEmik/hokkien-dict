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
    public private(set) var statusMessageKey: AppLocalizedStringKey?
    public private(set) var errorMessage: String?
    public private(set) var selectedLocale: AppLocale = .traditionalChinese
    public private(set) var selectedThemePreference: AppThemePreference = .system
    public private(set) var readingTextScale = 1.0
    public private(set) var librarySummary: DictionaryLibrarySummary?
    public private(set) var libraryMetadata: DictionaryLibraryMetadata?
    public private(set) var metadataBuiltAtDisplay: String?
    public private(set) var metadataSourceModifiedAtDisplay: String?
    public private(set) var isClearConfirmationPresented = false
    public private(set) var wordAudioSnapshot = DownloadSnapshot()
    public private(set) var sentenceAudioSnapshot = DownloadSnapshot()
    public private(set) var activeAudioActions = Set<AudioArchiveType>()

    private let library: DictionaryLibrary
    private let dateFormatter: any SettingsDateFormatting
    private let settingsStore: any AppSettingsStoring
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private var audioPollingTask: Task<Void, Never>?

    public init(
        library: DictionaryLibrary,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        dateFormatter: any SettingsDateFormatting = SettingsDateFormatter()
    ) {
        self.library = library
        self.settingsStore = settingsStore
        self.offlineAudioStore = offlineAudioStore
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
        await refreshAudioSnapshots()
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

    public func startAudioSnapshotPolling() {
        audioPollingTask?.cancel()
        audioPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshAudioSnapshots()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    public func stopAudioSnapshotPolling() {
        audioPollingTask?.cancel()
        audioPollingTask = nil
    }

    public func refreshAudioSnapshots() async {
        guard let offlineAudioStore else {
            wordAudioSnapshot = DownloadSnapshot()
            sentenceAudioSnapshot = DownloadSnapshot()
            return
        }

        wordAudioSnapshot = await offlineAudioStore.snapshot(for: .word)
        sentenceAudioSnapshot = await offlineAudioStore.snapshot(for: .sentence)
    }

    public func runAudioAction(_ action: AudioResourceAction, for type: AudioArchiveType) async {
        guard let offlineAudioStore, !activeAudioActions.contains(type) else {
            return
        }

        activeAudioActions.insert(type)
        defer { activeAudioActions.remove(type) }

        switch action {
        case .start:
            await offlineAudioStore.startDownload(type)
        case .pause:
            await offlineAudioStore.pauseDownload(type)
        case .resume:
            await offlineAudioStore.resumeDownload(type)
        case .restart:
            await offlineAudioStore.restartDownload(type)
        }

        await refreshAudioSnapshots()
    }

    public func snapshot(for type: AudioArchiveType) -> DownloadSnapshot {
        switch type {
        case .word:
            return wordAudioSnapshot
        case .sentence:
            return sentenceAudioSnapshot
        }
    }

    public func isAudioActionRunning(for type: AudioArchiveType) -> Bool {
        activeAudioActions.contains(type)
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
                statusMessageKey = .advancedRebuildCompleted
                let phase = await library.prepare()
                if case let .ready(summary) = phase {
                    librarySummary = summary
                }
                libraryMetadata = try? await library.metadata()
                refreshMetadataDisplay()
            case .clear:
                try await library.clearInstalledDatabase()
                statusMessageKey = .advancedClearCompleted
                librarySummary = nil
                libraryMetadata = nil
                refreshMetadataDisplay()
            }
            isRunningAction = false
            return true
        } catch {
            errorMessage = String(describing: error)
            statusMessageKey = nil
            isRunningAction = false
            return false
        }
    }

    private func refreshMetadataDisplay() {
        metadataBuiltAtDisplay = dateFormatter.displayString(from: libraryMetadata?.builtAt)
        metadataSourceModifiedAtDisplay = dateFormatter.displayString(from: libraryMetadata?.sourceModifiedAt)
    }
}

public extension SettingsViewModel {
    enum AudioResourceAction: Sendable {
        case start
        case pause
        case resume
        case restart
    }
}
