import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSTouchBarDelegate {

    let audioMonitor = SystemAudioMonitor()
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    private var controlStripVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
        setupTouchBar()
        setupControlStripShortcut()
        setupAlwaysVisibleTouchBar()
        observeAlwaysVisibleSetting()

        let current = Process()
        current.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        current.arguments = ["read", "com.apple.touchbar.agent", "PresentationModeGlobal"]
        let pipe = Pipe()
        current.standardOutput = pipe
        do {
            try current.run()
            current.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                                encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            controlStripVisible = (output == "appWithControlStrip")
        } catch {
            print("Failed to read Touch Bar state: \(error)")
        }
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
            let image = NSImage(systemSymbolName: "waveform",
                                accessibilityDescription: "SoundBar")
            button.image = image?.withSymbolConfiguration(config)
        }

        let menu = NSMenu()

        let open = NSMenuItem(title: "Open Settings",
                              action: #selector(openSettings),
                              keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "Show Control Strip  (⌥⇧C)",
                                action: #selector(toggleControlStripMenu),
                                keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

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
            .frame(minWidth: 640, idealWidth: 640, maxWidth: 640,
                   minHeight: 520, idealHeight: 520, maxHeight: 520)

        let hosting = NSHostingView(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.contentView = hosting
        win.setContentSize(NSSize(width: 640, height: 520))
        win.contentMinSize = NSSize(width: 640, height: 520)
        win.contentMaxSize = NSSize(width: 640, height: 520)
        win.center()
        win.title = "SoundBar"
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = win
        setupTouchBar()
    }

    // MARK: - Control Strip Toggle

    private func setupControlStripShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.option, .shift] && event.keyCode == 8 {
                self?.toggleControlStrip()
            }
        }
    }

    @objc func toggleControlStripMenu() {
        toggleControlStrip()
    }

    private func toggleControlStrip() {
        controlStripVisible.toggle()

        let task1 = Process()
        task1.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task1.arguments = [
            "write",
            "com.apple.touchbar.agent",
            "PresentationModeGlobal",
            controlStripVisible ? "appWithControlStrip" : "app"
        ]
        do { try task1.run(); task1.waitUntilExit() } catch { print("Failed to write Touch Bar state: \(error)") }

        for processName in ["ControlStrip", "TouchBarServer"] {
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            kill.arguments = [processName]
            do { try kill.run(); kill.waitUntilExit() } catch { }
        }

        if let menu = statusItem.menu,
           let item = menu.items.first(where: { $0.action == #selector(toggleControlStripMenu) }) {
            item.title = controlStripVisible
                ? "Hide Control Strip  (⌥⇧C)"
                : "Show Control Strip  (⌥⇧C)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.setupTouchBar()
        }
    }

    // MARK: - Always-Visible Touch Bar (private API)

    private var systemModalTouchBar: NSTouchBar?

    private func setupAlwaysVisibleTouchBar() {
        guard UserDefaults.standard.bool(forKey: "alwaysVisible") else { return }
        presentSystemModalTouchBar()
    }

    private func observeAlwaysVisibleSetting() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(alwaysVisibleSettingChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    @objc func alwaysVisibleSettingChanged() {
        DispatchQueue.main.async { [self] in
            if UserDefaults.standard.bool(forKey: "alwaysVisible") {
                presentSystemModalTouchBar()
            } else {
                dismissSystemModalTouchBar()
            }
        }
    }

    private func presentSystemModalTouchBar() {
        let sel = NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")
        guard let imp = (NSTouchBar.self as AnyObject).method(for: sel) else {
            print("presentSystemModalTouchBar: not available")
            return
        }
        typealias F = @convention(c) (AnyObject, Selector, NSTouchBar, Int, Any?) -> Void
        let f = unsafeBitCast(imp, to: F.self)
        let tb = makeTouchBar()
        systemModalTouchBar = tb
        f(NSTouchBar.self, sel, tb, 1, NSTouchBarItem.Identifier.visualizerItem as CFString)
    }

    private func dismissSystemModalTouchBar() {
        guard let tb = systemModalTouchBar else { return }
        let sel = NSSelectorFromString("dismissSystemModalTouchBar:")
        guard let imp = (NSTouchBar.self as AnyObject).method(for: sel) else {
            print("dismissSystemModalTouchBar: not available")
            return
        }
        typealias F = @convention(c) (AnyObject, Selector, NSTouchBar) -> Void
        let f = unsafeBitCast(imp, to: F.self)
        f(NSTouchBar.self, sel, tb)
        systemModalTouchBar = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        dismissSystemModalTouchBar()
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

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}

extension NSTouchBarItem.Identifier {
    static let visualizerItem = NSTouchBarItem.Identifier("com.soundbar.visualizer")
}
