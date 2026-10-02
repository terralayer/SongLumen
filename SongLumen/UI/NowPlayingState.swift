import Foundation

final class NowPlayingState {
    private(set) var snapshot: TrackSnapshot?
    private(set) var artwork: Data?

    func show(_ snapshot: TrackSnapshot) {
        self.snapshot = snapshot
        artwork = nil
    }

    func applyArtwork(_ data: Data, for id: String) {
        guard snapshot?.id == id else { return }
        artwork = data
    }
}
