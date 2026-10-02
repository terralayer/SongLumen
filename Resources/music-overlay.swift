import Cocoa

let displayDuration: TimeInterval = 3.0
let artworkRefreshInterval: TimeInterval = 0.1

if CommandLine.arguments.contains("--self-test") {
    print("duration=\(displayDuration)")
    print("artwork-refresh-interval=\(artworkRefreshInterval)")
    print("style=glow-card")
    exit(0)
}

guard CommandLine.arguments.count >= 4 else { exit(64) }

final class OverlayDelegate: NSObject, NSApplicationDelegate {
    private let artworkPath: String
    private let trackTitle: String
    private let artistName: String
    private var panel: NSPanel?
    private var imageView: NSImageView?
    private var artworkRefreshTimer: Timer?

    init(artworkPath: String, trackTitle: String, artistName: String) {
        self.artworkPath = artworkPath
        self.trackTitle = trackTitle
        self.artistName = artistName
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let width: CGFloat = 438
        let height: CGFloat = 126
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isMovable = false

        let background = NSVisualEffectView(frame: panel.contentView!.bounds)
        background.material = .underWindowBackground
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 22
        background.layer?.masksToBounds = true
        background.layer?.borderWidth = 1
        background.layer?.borderColor = NSColor(calibratedRed: 0.42, green: 0.45, blue: 0.96, alpha: 0.55).cgColor
        panel.contentView = background

        let imageView = NSImageView(frame: NSRect(x: 16, y: 16, width: 94, height: 94))
        imageView.imageScaling = .scaleAxesIndependently
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 16
        imageView.layer?.masksToBounds = true
        background.addSubview(imageView)
        self.imageView = imageView
        refreshArtwork()
        if imageView.image == nil {
            artworkRefreshTimer = Timer.scheduledTimer(withTimeInterval: artworkRefreshInterval, repeats: true) { [weak self] _ in
                self?.refreshArtwork()
            }
        }

        let heading = NSTextField(labelWithString: trackTitle)
        heading.frame = NSRect(x: 130, y: 68, width: 276, height: 26)
        heading.font = .systemFont(ofSize: 19, weight: .semibold)
        heading.lineBreakMode = .byTruncatingTail
        heading.textColor = .labelColor
        background.addSubview(heading)

        let subtitle = NSTextField(labelWithString: artistName)
        subtitle.frame = NSRect(x: 130, y: 39, width: 276, height: 22)
        subtitle.font = .systemFont(ofSize: 15, weight: .medium)
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.textColor = .secondaryLabelColor
        background.addSubview(subtitle)

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.maxX - width - 28, y: frame.maxY - height - 28))
        }
        self.panel = panel
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            NSApp.terminate(nil)
        }
    }

    private func refreshArtwork() {
        guard imageView?.image == nil, let artwork = NSImage(contentsOfFile: artworkPath) else { return }
        imageView?.image = artwork
        artworkRefreshTimer?.invalidate()
        artworkRefreshTimer = nil
    }
}

let delegate = OverlayDelegate(
    artworkPath: CommandLine.arguments[1],
    trackTitle: CommandLine.arguments[2],
    artistName: CommandLine.arguments[3]
)
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
