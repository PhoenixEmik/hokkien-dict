import Foundation

public protocol DictionaryRepositoryProtocol: Sendable {
    func loadBundle() async throws -> DictionaryBundle
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
    func metadata() async throws -> [String: String]? {
        nil
    }

    func supportsLocalMaintenance() async -> Bool {
        false
    }

    func rebuildInstalledDatabase() async throws {}

    func clearInstalledDatabase() async throws {}
}
