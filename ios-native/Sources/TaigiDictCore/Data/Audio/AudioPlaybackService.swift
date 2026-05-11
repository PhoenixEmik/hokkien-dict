import AVFoundation
import Foundation

public protocol AudioPlaybackControlling: Sendable {
    func play(clipURL: URL, clipID: String) async throws
    func stop() async
    func currentlyPlayingClipID() async -> String?
}

public actor AudioPlaybackService: NSObject, AudioPlaybackControlling {
    private var player: AVAudioPlayer?
    private var activeClipID: String?

    public override init() {
        super.init()
    }

    public func play(clipURL: URL, clipID: String) async throws {
        if activeClipID == clipID, player?.isPlaying == true {
            player?.stop()
            activeClipID = nil
            return
        }

        try configureAudioSessionIfNeeded()

        let nextPlayer = try AVAudioPlayer(contentsOf: clipURL)
        nextPlayer.prepareToPlay()
        guard nextPlayer.play() else {
            throw AudioPlaybackError.unableToStartPlayback
        }

        player = nextPlayer
        activeClipID = clipID
    }

    public func stop() async {
        player?.stop()
        activeClipID = nil
    }

    public func currentlyPlayingClipID() async -> String? {
        if player?.isPlaying == true {
            return activeClipID
        }
        return nil
    }

    private func configureAudioSessionIfNeeded() throws {
#if os(iOS) || os(tvOS) || os(watchOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true)
#endif
    }
}

public enum AudioPlaybackError: Error, Equatable {
    case unableToStartPlayback
}
