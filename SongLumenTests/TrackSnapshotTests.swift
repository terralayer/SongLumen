import XCTest
@testable import SongLumen

final class TrackSnapshotTests: XCTestCase {
    func testSnapshotsWithSameValuesAreEqual() {
        XCTAssertEqual(
            TrackSnapshot(id: "a", title: "One", artist: "A"),
            TrackSnapshot(id: "a", title: "One", artist: "A")
        )
    }

    func testSnapshotsWithDifferentIDsAreNotEqual() {
        XCTAssertNotEqual(
            TrackSnapshot(id: "a", title: "One", artist: "A"),
            TrackSnapshot(id: "b", title: "One", artist: "A")
        )
    }
}
