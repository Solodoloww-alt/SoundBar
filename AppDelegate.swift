import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSTouchBarDelegate {

    let audioMonitor = SystemAudioMonitor()
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
        setupTouchBar()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        setupTouchBar()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        setupTouchBar()
        return false
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "SoundBar")
            button.image = image?.withSymbolConfiguration(config)
        }

        let menu = NSMenu()

        let open = NSMenuItem(title: "Open Settings",
                              action: #selector(openSettings),
                              keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit SoundBar",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        if let win = settingsWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(audioMonitor: audioMonitor)
        let hosting = NSHostingView(rootView: view)
        hosting.setFrameSize(NSSize(width: 440, height: 640))

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.contentView = hosting
        win.center()
        win.title = "SoundBar"
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = win
        setupTouchBar()
    }

    // MARK: - Touch Bar

    func setupTouchBar() {
        let tb = makeTouchBar()
        NSApp.touchBar = tb
        NSApp.windows.forEach { $0.touchBar = tb }
    }

    func makeTouchBar() -> NSTouchBar {
        let tb = NSTouchBar()
        tb.delegate = self
        tb.defaultItemIdentifiers  = [.visualizerItem]
        tb.principalItemIdentifier = .visualizerItem
        return tb
    }

    func touchBar(_ touchBar: NSTouchBar,
                  makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == .visualizerItem else { return nil }
        let item = NSCustomTouchBarItem(identifier: identifier)
        let host = FullWidthHostingView(
            rootView: TouchBarVisualizerView(audioMonitor: audioMonitor)
        )
        host.frame.size.height = 30
        item.view = host
        return item
    }
}

// MARK: - Window Delegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}

// MARK: - Identifiers

extension NSTouchBarItem.Identifier {
    static let visualizerItem = NSTouchBarItem.Identifier("com.soundbar.visualizer")
}
