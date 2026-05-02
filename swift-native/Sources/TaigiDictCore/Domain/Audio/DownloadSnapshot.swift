import Foundation

public struct DownloadSnapshot: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case downloading
        case paused
        case completed
        case failed(String)
    }

    public var state: State
    public var downloadedBytes: Int64
    public var totalBytes: Int64?

    public init(state: State = .idle, downloadedBytes: Int64 = 0, totalBytes: Int64? = nil) {
        self.state = state
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }

    public var progress: Double? {
        guard let totalBytes, totalBytes > 0 else {
            return nil
        }
        return min(max(Double(downloadedBytes) / Double(totalBytes), 0), 1)
    }
}
