import AppKit

final class NowPlayingPanel: NSPanel {
    private let titleLabel = NSTextField(labelWithString: "")
    private let artistLabel = NSTextField(labelWithString: "")
    private let artworkView = NSImageView()

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 360, height: 110), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        contentView = NSVisualEffectView()
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 20
        contentView?.layer?.masksToBounds = true
        artworkView.frame = NSRect(x: 14, y: 14, width: 82, height: 82)
        artworkView.imageScaling = .scaleAxesIndependently
        titleLabel.frame = NSRect(x: 112, y: 61, width: 230, height: 24)
        titleLabel.font = .boldSystemFont(ofSize: 16)
        artistLabel.frame = NSRect(x: 112, y: 35, width: 230, height: 20)
        artistLabel.textColor = .secondaryLabelColor
        contentView?.addSubview(artworkView)
        contentView?.addSubview(titleLabel)
        contentView?.addSubview(artistLabel)
    }

    func render(_ state: NowPlayingState) {
        titleLabel.stringValue = state.snapshot?.title ?? ""
        artistLabel.stringValue = state.snapshot?.artist ?? ""
        artworkView.image = state.artwork.flatMap(NSImage.init(data:))
        orderFrontRegardless()
    }
}
