import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = MusicMonitor()
    private let state = NowPlayingState()
    private let panel = NowPlayingPanel()
    private let artworkLoader = ArtworkLoader()
    private let loginItem = LoginItemController()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "♫"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Monitoring Music", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: loginItem.menuTitle, action: #selector(toggleLoginItem), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit SongLumen", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
        monitor.onTrackChange = { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                self.state.show(snapshot)
                self.panel.render(self.state)
                self.artworkLoader.load(for: snapshot) { [weak self] id, data in
                    DispatchQueue.main.async {
                        guard let self, let data else { return }
                        self.state.applyArtwork(data, for: id)
                        self.panel.render(self.state)
                    }
                }
            }
        }
        monitor.onStatusChange = { [weak self] status in
            DispatchQueue.main.async { self?.statusItem.button?.title = status == .monitoring ? "♫" : "♫ !" }
        }
        monitor.start()
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        do { try loginItem.toggle(); sender.title = loginItem.menuTitle }
        catch { sender.title = "Start at Login Unavailable" }
    }
}
