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
    public private(set) var librarySummary: DictionaryLibrarySummary?
    public private(set) var libraryMetadata: DictionaryLibraryMetadata?
    public private(set) var metadataBuiltAtDisplay: String?
    public private(set) var metadataSourceModifiedAtDisplay: String?
    public private(set) var isClearConfirmationPresented = false

    private let library: DictionaryLibrary
    private let dateFormatter: any SettingsDateFormatting

    public init(
        library: DictionaryLibrary,
        dateFormatter: any SettingsDateFormatting = SettingsDateFormatter()
    ) {
        self.library = library
        self.dateFormatter = dateFormatter
    }

    public func loadCapabilities() async {
        errorMessage = nil
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
