import XCTest
@testable import SongLumen

final class ArtworkLoaderTests: XCTestCase {
    func testRetryPolicyMatchesArtworkDeadline() {
        let policy = ArtworkRetryPolicy.default
        XCTAssertEqual(policy.maximumAttempts, 15)
        XCTAssertEqual(policy.delay, 0.2)
    }
}
