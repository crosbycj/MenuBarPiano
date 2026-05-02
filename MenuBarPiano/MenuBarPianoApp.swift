import AppKit
import Carbon

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: AppDelegate?

    private let controller = PianoController()
    private var statusItemController: StatusItemController?
    private var toggleHotKey: GlobalHotKey?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        sharedDelegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        delegate.installStatusItem()
        delegate.installToggleHotKey()
        FileHandle.standardError.write(Data("MenuBarPiano ready. Menu bar item is ♫.\n".utf8))
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()
        installToggleHotKey()
    }

    private func installStatusItem() {
        guard statusItemController == nil else {
            return
        }

        let statusItemController = StatusItemController(controller: controller)
        self.statusItemController = statusItemController
        statusItemController.install()
    }

    private func installToggleHotKey() {
        guard toggleHotKey == nil else {
            return
        }

        let hotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_M),
            modifiers: UInt32(optionKey | shiftKey)
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePlayback()
            }
        }

        if hotKey.register() {
            toggleHotKey = hotKey
        } else {
            FileHandle.standardError.write(Data("MenuBarPiano could not register hotkey Option+Shift+M.\n".utf8))
        }
    }

    private func togglePlayback() {
        controller.setEnabled(!controller.isEnabled)
        statusItemController?.refreshMenu()
    }
}

private final class StatusItemController: NSObject, NSMenuDelegate {
    private let controller: PianoController
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    init(controller: PianoController) {
        self.controller = controller
        super.init()
    }

    func install() {
        guard statusItem == nil else {
            return
        }

        let menu = NSMenu()
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        menu.delegate = self
        statusItem.menu = menu
        self.menu = menu
        self.statusItem = statusItem

        if let button = statusItem.button {
            button.title = "♫"
            button.toolTip = "MenuBar Piano"
        }

        rebuildMenu()
    }

    func refreshMenu() {
        rebuildMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        controller.refreshPermissions()
        rebuildMenu()
    }

    private func rebuildMenu() {
        guard let menu else {
            return
        }

        menu.removeAllItems()

        let playbackTitle = controller.isEnabled ? "⏸ Stop" : "▶ Start"
        let playback = NSMenuItem(title: playbackTitle, action: #selector(togglePlayback), keyEquivalent: "")
        playback.target = self
        menu.addItem(playback)

        menu.addItem(.separator())

        for song in controller.songs {
            let item = NSMenuItem(title: song.name, action: #selector(selectSong(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = song.name
            item.state = song == controller.selectedSong ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let loop = NSMenuItem(title: "Loop", action: #selector(toggleLoop), keyEquivalent: "")
        loop.target = self
        loop.state = controller.loopEnabled ? .on : .off
        menu.addItem(loop)

        let resetAfterPause = NSMenuItem(title: "Reset after pause", action: #selector(toggleResetAfterPause), keyEquivalent: "")
        resetAfterPause.target = self
        resetAfterPause.state = controller.resetAfterPauseEnabled ? .on : .off
        menu.addItem(resetAfterPause)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func selectSong(_ sender: NSMenuItem) {
        guard
            let songName = sender.representedObject as? String,
            let song = controller.songs.first(where: { $0.name == songName })
        else {
            return
        }

        controller.select(song)
        rebuildMenu()
    }

    @objc private func togglePlayback() {
        controller.setEnabled(!controller.isEnabled)
        rebuildMenu()
    }

    @objc private func toggleLoop() {
        controller.toggleLoop()
        rebuildMenu()
    }

    @objc private func toggleResetAfterPause() {
        controller.toggleResetAfterPause()
        rebuildMenu()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private final class GlobalHotKey {
    private let keyCode: UInt32
    private let modifiers: UInt32
    private let handler: () -> Void
    private let hotKeyID = EventHotKeyID(signature: 0x4D42504D, id: 1)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.handler = handler
    }

    deinit {
        unregister()
    }

    func register() -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()

        let eventHandlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            globalHotKeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard eventHandlerStatus == noErr else {
            eventHandlerRef = nil
            return false
        }

        let hotKeyStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard hotKeyStatus == noErr else {
            unregister()
            return false
        }

        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        hotKeyRef = nil
        eventHandlerRef = nil
    }

    fileprivate func handle() {
        handler()
    }
}

private func globalHotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else {
        return noErr
    }

    let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
    hotKey.handle()
    return noErr
}
