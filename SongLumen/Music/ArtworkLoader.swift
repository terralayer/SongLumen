import Foundation

struct ArtworkRetryPolicy: Equatable {
    let maximumAttempts: Int
    let delay: TimeInterval
    static let `default` = ArtworkRetryPolicy(maximumAttempts: 15, delay: 0.2)
}

final class ArtworkLoader {
    let retryPolicy: ArtworkRetryPolicy

    init(retryPolicy: ArtworkRetryPolicy = .default) {
        self.retryPolicy = retryPolicy
    }

    func load(for snapshot: TrackSnapshot, completion: @escaping (String, Data?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("artwork-\(snapshot.id).png")
            if let data = try? Data(contentsOf: cache) {
                completion(snapshot.id, data)
                return
            }
            for attempt in 0..<self.retryPolicy.maximumAttempts {
                if let data = self.currentArtwork() {
                    try? data.write(to: cache, options: .atomic)
                    completion(snapshot.id, data)
                    return
                }
                Thread.sleep(forTimeInterval: self.retryPolicy.delay)
                if attempt + 1 == self.retryPolicy.maximumAttempts { completion(snapshot.id, nil) }
            }
        }
    }

    private func currentArtwork() -> Data? {
        let source = """
        tell application \"Music\"
          if player state is playing and (count of artworks of current track) > 0 then
            return data of artwork 1 of current track
          end if
        end tell
        """
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        return error == nil ? result.data : nil
    }
}
