import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let label = "com.terrahomelab.music-track-notifier"
    private var statusItem: NSStatusItem!
    private var agentURL: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/\(label).plist") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "♫"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Now Playing", action: #selector(start), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Stop Now Playing", action: #selector(stop), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
        start()
    }

    @objc private func start() { install(); run(["bootstrap", "gui/\(getuid())", agentURL.path]); statusItem.button?.title = "♫ On" }
    @objc private func stop() { run(["bootout", "gui/\(getuid())/\(label)"]); statusItem.button?.title = "♫ Off" }
    @objc private func quit() { NSApp.terminate(nil) }

    private func install() {
        guard let templateURL = Bundle.main.url(forResource: "\(label).plist", withExtension: "template"),
              let watcherURL = Bundle.main.url(forResource: "music-track-notifier", withExtension: "sh"),
              var text = try? String(contentsOf: templateURL) else { return }
        text = text.replacingOccurrences(of: "__WATCHER_PATH__", with: watcherURL.path)
        try? FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? text.write(to: agentURL, atomically: true, encoding: .utf8)
        run(["bootout", "gui/\(getuid())/\(label)"])
    }

    private func run(_ arguments: [String]) { let process = Process(); process.executableURL = URL(fileURLWithPath: "/bin/launchctl"); process.arguments = arguments; try? process.run(); process.waitUntilExit() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
