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

    private let library: DictionaryLibrary

    public init(library: DictionaryLibrary) {
        self.library = library
    }

    public func loadCapabilities() async {
        errorMessage = nil
        supportsDataMaintenance = await library.supportsLocalMaintenance()
    }

    @discardableResult
    public func run(_ action: MaintenanceAction) async -> Bool {
        guard !isRunningAction else {
            return false
        }

        isRunningAction = true
        errorMessage = nil

        do {
            switch action {
            case .rebuild:
                try await library.rebuildInstalledDatabase()
                statusMessage = "本機辭典資料已重建。"
            case .clear:
                try await library.clearInstalledDatabase()
                statusMessage = "本機辭典資料已清除。"
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
}
