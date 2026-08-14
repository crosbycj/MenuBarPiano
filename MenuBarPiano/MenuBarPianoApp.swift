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
        controller.reloadUserSongs()
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
        playback.isEnabled = controller.canListenForKeystrokes
        menu.addItem(playback)

        if !controller.canListenForKeystrokes {
            let permission = NSMenuItem(
                title: "Needs Input Monitoring — Open System Settings…",
                action: #selector(openInputMonitoringSettings),
                keyEquivalent: ""
            )
            permission.target = self
            menu.addItem(permission)
        } else if let error = controller.lastError {
            let errorItem = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())

        let freePlay = NSMenuItem(title: "Free Play", action: #selector(selectFreePlay), keyEquivalent: "")
        freePlay.target = self
        freePlay.state = controller.selectedMode == .freePlay ? .on : .off
        menu.addItem(freePlay)

        for group in groupedSongsByCategory() {
            let categoryItem = NSMenuItem(title: group.category, action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: group.category)

            for song in group.songs {
                let item = NSMenuItem(title: song.name, action: #selector(selectSong(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = song.id
                item.state = controller.selectedMode == .song(song) ? .on : .off
                submenu.addItem(item)
            }

            menu.addItem(categoryItem)
            menu.setSubmenu(submenu, for: categoryItem)
        }

        let addSongs = NSMenuItem(title: "Add Songs…", action: #selector(addSongs), keyEquivalent: "")
        addSongs.target = self
        menu.addItem(addSongs)

        menu.addItem(.separator())

        if controller.selectedScript != nil {
            let copyScript = NSMenuItem(title: "Copy typing script", action: #selector(copyTypingScript), keyEquivalent: "")
            copyScript.target = self
            menu.addItem(copyScript)
            menu.addItem(.separator())
        }

        let loop = NSMenuItem(title: "Loop", action: #selector(toggleLoop), keyEquivalent: "")
        loop.target = self
        loop.state = controller.loopEnabled ? .on : .off
        loop.isEnabled = controller.selectedMode != .freePlay
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

    private func groupedSongsByCategory() -> [(category: String, songs: [Song])] {
        var groups: [(category: String, songs: [Song])] = []
        var categoryIndexes: [String: Int] = [:]

        for song in controller.allSongs {
            if let index = categoryIndexes[song.category] {
                groups[index].songs.append(song)
            } else {
                categoryIndexes[song.category] = groups.count
                groups.append((category: song.category, songs: [song]))
            }
        }

        return groups
    }

    @objc private func selectSong(_ sender: NSMenuItem) {
        guard
            let songID = sender.representedObject as? String,
            let song = controller.allSongs.first(where: { $0.id == songID })
        else {
            return
        }

        controller.select(song)
        rebuildMenu()
    }

    @objc private func selectFreePlay() {
        controller.selectFreePlay()
        rebuildMenu()
    }

    @objc private func addSongs() {
        do {
            try UserSongLibrary.createDirectory()
            NSWorkspace.shared.open(UserSongLibrary.songsDirectory)
        } catch {
            FileHandle.standardError.write(Data("MenuBarPiano could not create the Songs folder: \(error)\n".utf8))
        }
    }

    @objc private func openInputMonitoringSettings() {
        controller.requestInputMonitoringPermission()
        rebuildMenu()
    }

    @objc private func copyTypingScript() {
        guard let script = controller.selectedScript else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(script, forType: .string)
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
