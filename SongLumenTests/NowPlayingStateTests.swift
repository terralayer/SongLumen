import XCTest
@testable import SongLumen

final class NowPlayingStateTests: XCTestCase {
    func testStaleArtworkIsRejectedAfterTrackChanges() {
        let state = NowPlayingState()
        let first = TrackSnapshot(id: "first", title: "First", artist: "A")
        let second = TrackSnapshot(id: "second", title: "Second", artist: "B")

        state.show(first)
        state.show(second)
        state.applyArtwork(Data([1]), for: first.id)

        XCTAssertNil(state.artwork)
    }
}
