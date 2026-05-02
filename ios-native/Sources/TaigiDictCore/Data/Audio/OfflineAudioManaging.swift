import Foundation

public protocol OfflineAudioManaging: Sendable {
    func snapshot(for type: AudioArchiveType) async -> DownloadSnapshot
    func startDownload(_ type: AudioArchiveType) async
    func pauseDownload(_ type: AudioArchiveType) async
    func resumeDownload(_ type: AudioArchiveType) async
    func restartDownload(_ type: AudioArchiveType) async
    func playClip(_ clipID: String, from type: AudioArchiveType) async throws
    func currentlyPlayingClipID() async -> String?
}
