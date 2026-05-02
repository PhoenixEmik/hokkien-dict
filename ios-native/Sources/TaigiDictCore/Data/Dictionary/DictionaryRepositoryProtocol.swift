import Foundation

public enum DictionaryPreparationStep: Equatable, Sendable {
    case checkingPackage
    case importingDatabase
    case loadingBundle
}

public struct DictionaryPreparationProgress: Equatable, Sendable {
    public var step: DictionaryPreparationStep
    public var fraction: Double
    public var completedUnits: Int
    public var totalUnits: Int
    public var message: String?

    public init(
        step: DictionaryPreparationStep,
        fraction: Double,
        completedUnits: Int,
        totalUnits: Int,
        message: String? = nil
    ) {
        self.step = step
        self.fraction = max(0, min(fraction, 1))
        self.completedUnits = completedUnits
        self.totalUnits = max(totalUnits, 1)
        self.message = message
    }
}

public protocol DictionaryRepositoryProtocol: Sendable {
    func loadBundle() async throws -> DictionaryBundle
    func loadBundle(
        onProgress: (@Sendable (DictionaryPreparationProgress) async -> Void)?
    ) async throws -> DictionaryBundle
    func search(_ rawQuery: String, limit: Int, offset: Int) async throws -> [DictionaryEntry]
    func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry?
    func entries(ids: [Int64]) async throws -> [DictionaryEntry]
    func entry(id: Int64) async throws -> DictionaryEntry?
    func metadata() async throws -> [String: String]?
    func clearBundleCache() async
    func supportsLocalMaintenance() async -> Bool
    func rebuildInstalledDatabase() async throws
    func clearInstalledDatabase() async throws
}

public extension DictionaryRepositoryProtocol {
    func loadBundle(
        onProgress: (@Sendable (DictionaryPreparationProgress) async -> Void)?
    ) async throws -> DictionaryBundle {
        if let onProgress {
            await onProgress(
                DictionaryPreparationProgress(
                    step: .loadingBundle,
                    fraction: 0,
                    completedUnits: 0,
                    totalUnits: 1
                )
            )
        }

        let bundle = try await loadBundle()

        if let onProgress {
            await onProgress(
                DictionaryPreparationProgress(
                    step: .loadingBundle,
                    fraction: 1,
                    completedUnits: 1,
                    totalUnits: 1
                )
            )
        }

        return bundle
    }

    func metadata() async throws -> [String: String]? {
        nil
    }

    func supportsLocalMaintenance() async -> Bool {
        false
    }

    func rebuildInstalledDatabase() async throws {}

    func clearInstalledDatabase() async throws {}
}
