import Foundation

final class MusicMonitor {
    enum Status: Equatable { case idle, monitoring, permissionDenied }

    var onTrackChange: ((TrackSnapshot) -> Void)?
    var onStatusChange: ((Status) -> Void)?
    private var timer: Timer?
    private var lastTrackID: String?

    func start() {
        stop()
        onStatusChange?(.monitoring)
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.poll() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onStatusChange?(.idle)
    }

    private func poll() {
        let source = """
        tell application \"Music\"
          if player state is playing then
            set t to current track
            return (persistent ID of t) & tab & (name of t) & tab & (artist of t)
          end if
        end tell
        """
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return }
        let result = script.executeAndReturnError(&error)
        guard error == nil else {
            onStatusChange?(.permissionDenied)
            return
        }
        let fields = result.stringValue?.split(separator: "\t", maxSplits: 2).map(String.init) ?? []
        guard fields.count == 3, fields[0] != lastTrackID else { return }
        lastTrackID = fields[0]
        onTrackChange?(TrackSnapshot(id: fields[0], title: fields[1], artist: fields[2]))
    }
}
