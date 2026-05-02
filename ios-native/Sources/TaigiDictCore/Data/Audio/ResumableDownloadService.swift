import Foundation

private enum DownloadEvent {
    case response(URLResponse)
    case data(Data)
}

public protocol ResumableDownloading: Sendable {
    func startDownload(id: String, from remoteURL: URL, to localURL: URL) async
    func pauseDownload(id: String) async
    func resumeDownload(id: String) async
    func restartDownload(id: String, from remoteURL: URL, to localURL: URL) async
    func snapshot(for id: String) async -> DownloadSnapshot
}

public actor ResumableDownloadService: ResumableDownloading {
    private struct DownloadJob {
        var remoteURL: URL
        var localURL: URL
        var task: Task<Void, Never>?
    }

    private let snapshotUpdateByteInterval: Int64 = 256 * 1024

    private let fileManager: FileManager
    private let session: URLSession
    private var jobs: [String: DownloadJob] = [:]
    private var snapshots: [String: DownloadSnapshot] = [:]

    public init(session: URLSession = .shared, fileManager: FileManager = .default) {
        self.session = session
        self.fileManager = fileManager
    }

    public func startDownload(id: String, from remoteURL: URL, to localURL: URL) async {
        if snapshots[id]?.state == .downloading {
            return
        }

        upsertJob(id: id, remoteURL: remoteURL, localURL: localURL)
        beginDownload(id: id, restart: false)
    }

    public func pauseDownload(id: String) async {
        guard var job = jobs[id] else {
            return
        }

        job.task?.cancel()
        job.task = nil
        jobs[id] = job

        var snapshot = snapshots[id] ?? DownloadSnapshot()
        if snapshot.state == .downloading {
            snapshot.state = .paused
        }
        snapshots[id] = snapshot
    }

    public func resumeDownload(id: String) async {
        guard jobs[id] != nil else {
            return
        }

        beginDownload(id: id, restart: false)
    }

    public func restartDownload(id: String, from remoteURL: URL, to localURL: URL) async {
        await pauseDownload(id: id)
        try? fileManager.removeItem(at: localURL)

        snapshots[id] = DownloadSnapshot(state: .idle, downloadedBytes: 0, totalBytes: nil)
        upsertJob(id: id, remoteURL: remoteURL, localURL: localURL)
        beginDownload(id: id, restart: true)
    }

    public func snapshot(for id: String) async -> DownloadSnapshot {
        snapshots[id] ?? DownloadSnapshot()
    }

    private func upsertJob(id: String, remoteURL: URL, localURL: URL) {
        let existing = jobs[id]
        existing?.task?.cancel()
        jobs[id] = DownloadJob(remoteURL: remoteURL, localURL: localURL, task: nil)
    }

    private func beginDownload(id: String, restart: Bool) {
        guard var job = jobs[id] else {
            return
        }

        job.task?.cancel()
        job.task = Task { [weak self] in
            await self?.runDownload(id: id)
        }
        jobs[id] = job

        var snapshot = snapshots[id] ?? DownloadSnapshot()
        if restart {
            snapshot.downloadedBytes = 0
            snapshot.totalBytes = nil
        }
        snapshot.state = .downloading
        snapshots[id] = snapshot
    }

    private func runDownload(id: String) async {
        guard let job = jobs[id] else {
            return
        }

        do {
            try ensureParentDirectory(for: job.localURL)

            let existingBytes = fileSize(of: job.localURL)
            var request = URLRequest(url: job.remoteURL)
            if existingBytes > 0 {
                request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
            }

            var handle: FileHandle?
            var downloadedBytes: Int64 = 0
            var lastReportedBytes: Int64 = 0
            var totalBytes: Int64?

            defer {
                try? handle?.close()
            }

            for try await event in ChunkedDownloadStream.events(for: request, configuration: session.configuration) {
                try Task.checkCancellation()

                switch event {
                case .response(let response):
                    try validateResponse(response)

                    let resumedResponse = isResumedResponse(response)
                    let shouldAppend = existingBytes > 0 && resumedResponse
                    if existingBytes > 0 && !shouldAppend {
                        try? fileManager.removeItem(at: job.localURL)
                    }

                    let baselineBytes: Int64 = shouldAppend ? existingBytes : 0
                    downloadedBytes = baselineBytes
                    lastReportedBytes = baselineBytes
                    totalBytes = resolveTotalBytes(response: response, currentSize: baselineBytes)

                    var snapshot = snapshots[id] ?? DownloadSnapshot()
                    snapshot.state = .downloading
                    snapshot.downloadedBytes = baselineBytes
                    snapshot.totalBytes = totalBytes
                    snapshots[id] = snapshot

                    if shouldAppend, fileManager.fileExists(atPath: job.localURL.path) {
                        handle = try FileHandle(forWritingTo: job.localURL)
                        try handle?.seekToEnd()
                    } else {
                        fileManager.createFile(atPath: job.localURL.path, contents: nil)
                        handle = try FileHandle(forWritingTo: job.localURL)
                    }

                case .data(let data):
                    guard let handle else {
                        throw URLError(.badServerResponse)
                    }

                    try handle.write(contentsOf: data)
                    downloadedBytes += Int64(data.count)

                    if downloadedBytes - lastReportedBytes >= snapshotUpdateByteInterval {
                        var rolling = snapshots[id] ?? DownloadSnapshot(state: .downloading)
                        rolling.downloadedBytes = downloadedBytes
                        rolling.totalBytes = totalBytes
                        snapshots[id] = rolling
                        lastReportedBytes = downloadedBytes
                    }
                }
            }

            var completed = snapshots[id] ?? DownloadSnapshot()
            completed.state = .completed
            completed.downloadedBytes = downloadedBytes
            completed.totalBytes = totalBytes ?? downloadedBytes
            snapshots[id] = completed

            var finishedJob = jobs[id]
            finishedJob?.task = nil
            if let finishedJob {
                jobs[id] = finishedJob
            }
        } catch is CancellationError {
            // pause/restart manages state updates.
        } catch {
            var failed = snapshots[id] ?? DownloadSnapshot()
            failed.state = .failed(error.localizedDescription)
            snapshots[id] = failed

            var failedJob = jobs[id]
            failedJob?.task = nil
            if let failedJob {
                jobs[id] = failedJob
            }
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func isResumedResponse(_ response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        if httpResponse.statusCode == 206 {
            return true
        }

        return httpResponse.value(forHTTPHeaderField: "Content-Range") != nil
    }

    private func ensureParentDirectory(for fileURL: URL) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileSize(of fileURL: URL) -> Int64 {
        guard
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = values.fileSize
        else {
            return 0
        }

        return Int64(fileSize)
    }

    private func resolveTotalBytes(response: URLResponse, currentSize: Int64) -> Int64? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range"),
           let totalPart = contentRange.split(separator: "/").last,
           let total = Int64(totalPart) {
            return total
        }

        if response.expectedContentLength > 0 {
            return currentSize + response.expectedContentLength
        }

        return nil
    }
}

private final class ChunkedDownloadStream: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let continuation: AsyncThrowingStream<DownloadEvent, Error>.Continuation
    private var session: URLSession?

    private init(continuation: AsyncThrowingStream<DownloadEvent, Error>.Continuation) {
        self.continuation = continuation
    }

    static func events(
        for request: URLRequest,
        configuration: URLSessionConfiguration
    ) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            let delegate = ChunkedDownloadStream(continuation: continuation)
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            delegate.session = session

            let task = session.dataTask(with: request)
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                session.invalidateAndCancel()
                _ = delegate
            }
            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        continuation.yield(.response(response))
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        continuation.yield(.data(data))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            continuation.finish(throwing: error)
        } else {
            continuation.finish()
        }
        self.session?.finishTasksAndInvalidate()
        self.session = nil
    }
}
