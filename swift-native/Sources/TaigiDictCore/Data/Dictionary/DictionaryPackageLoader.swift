import CryptoKit
import Foundation

public enum DictionaryPackageLoaderError: Error, Equatable {
    case missingManifest(URL)
    case missingEntries(URL)
    case checksumMismatch(expected: String, actual: String)
}

public struct DictionaryPackageLoader: Sendable {
    private let decoder: JSONDecoder
    private let importService: DictionaryImportService

    public init(
        decoder: JSONDecoder = JSONDecoder(),
        importService: DictionaryImportService = DictionaryImportService()
    ) {
        self.decoder = decoder
        self.importService = importService
    }

    public func loadBundle(from directory: URL) throws -> DictionaryBundle {
        let manifestURL = directory.appendingPathComponent("dictionary_manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw DictionaryPackageLoaderError.missingManifest(manifestURL)
        }

        let manifest = try decoder.decode(
            DictionaryManifest.self,
            from: try Data(contentsOf: manifestURL)
        )
        let entriesURL = directory.appendingPathComponent(manifest.entriesFileName)
        guard FileManager.default.fileExists(atPath: entriesURL.path) else {
            throw DictionaryPackageLoaderError.missingEntries(entriesURL)
        }

        let entriesData = try Data(contentsOf: entriesURL)
        if let expectedChecksum = manifest.checksumSHA256, !expectedChecksum.isEmpty {
            let actualChecksum = SHA256.hash(data: entriesData).hexString
            guard actualChecksum.caseInsensitiveCompare(expectedChecksum) == .orderedSame else {
                throw DictionaryPackageLoaderError.checksumMismatch(
                    expected: expectedChecksum,
                    actual: actualChecksum
                )
            }
        }

        return try importService.importBundle(
            manifest: manifest,
            entriesData: entriesData
        )
    }
}

private extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
