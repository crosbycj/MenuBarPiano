import AppKit
import SwiftUI

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: AppDelegate?

    private let controller = PianoController()
    private var statusItemController: StatusItemController?
    private var controlPanel: NSPanel?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        sharedDelegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        delegate.installStatusItem()
        delegate.showControlPanel()
        FileHandle.standardError.write(Data("MenuBarPiano ready. Control panel is open; menu bar item is named 'Piano'.\n".utf8))
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()
        showControlPanel()
    }

    private func installStatusItem() {
        guard statusItemController == nil else {
            return
        }

        let statusItemController = StatusItemController(controller: controller)
        statusItemController.onShowControls = { [weak self] in
            self?.showControlPanel()
        }
        self.statusItemController = statusItemController
        statusItemController.install()
    }

    private func showControlPanel() {
        if let controlPanel {
            controlPanel.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 420),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "MenuBar Piano"
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.contentView = NSHostingView(rootView: PianoControlPanel(controller: controller))
        panel.center()

        controlPanel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

private final class StatusItemController: NSObject, NSMenuDelegate {
    private let controller: PianoController
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    var onShowControls: (() -> Void)?

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
            let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "MenuBar Piano")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.title = "Piano"
            button.toolTip = "MenuBar Piano"
        }

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

        let controls = NSMenuItem(title: "Show Controls", action: #selector(showControls), keyEquivalent: "")
        controls.target = self
        menu.addItem(controls)
        menu.addItem(.separator())

        let header = NSMenuItem(title: "Song", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for song in controller.songs {
            let item = NSMenuItem(title: song.name, action: #selector(selectSong(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = song.name
            item.state = song == controller.selectedSong ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let testNote = NSMenuItem(title: "Play Test Note", action: #selector(playTestNote), keyEquivalent: "")
        testNote.target = self
        menu.addItem(testNote)

        if !controller.hasAccessibilityPermission {
            let access = NSMenuItem(title: "Accessibility access required", action: nil, keyEquivalent: "")
            access.isEnabled = false
            menu.addItem(access)

            let grant = NSMenuItem(title: "Grant Access...", action: #selector(grantAccess), keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
        }

        if !controller.hasInputMonitoringPermission {
            let access = NSMenuItem(title: "Input Monitoring access required", action: nil, keyEquivalent: "")
            access.isEnabled = false
            menu.addItem(access)

            let grant = NSMenuItem(title: "Grant Input Monitoring...", action: #selector(grantInputMonitoring), keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
        }

        let toggleTitle = controller.isEnabled ? "Turn Off" : "Turn On"
        let toggle = NSMenuItem(title: toggleTitle, action: #selector(togglePlayback), keyEquivalent: "")
        toggle.target = self
        toggle.isEnabled = controller.canListenForKeystrokes
        toggle.state = controller.isEnabled ? .on : .off
        menu.addItem(toggle)

        if let lastError = controller.lastError {
            let error = NSMenuItem(title: lastError, action: nil, keyEquivalent: "")
            error.isEnabled = false
            menu.addItem(error)
        }

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

    @objc private func grantAccess() {
        controller.requestAccessibilityPermission()
        rebuildMenu()
    }

    @objc private func grantInputMonitoring() {
        controller.requestInputMonitoringPermission()
        rebuildMenu()
    }

    @objc private func playTestNote() {
        controller.playPreviewNote()
    }

    @objc private func showControls() {
        onShowControls?()
    }

    @objc private func togglePlayback() {
        controller.setEnabled(!controller.isEnabled)
        rebuildMenu()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private struct PianoControlPanel: View {
    @ObservedObject var controller: PianoController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuBar Piano")
                        .font(.title3.weight(.semibold))
                    Text("The menu bar item is still installed as Piano.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Picker(
                "Song",
                selection: Binding(
                    get: { controller.selectedSong },
                    set: { controller.select($0) }
                )
            ) {
                ForEach(controller.songs) { song in
                    Text(song.name).tag(song)
                }
            }

            HStack(spacing: 10) {
                Button("Play Test Note") {
                    controller.playPreviewNote()
                }

                Button("Refresh Access") {
                    controller.refreshPermissions()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                permissionRow(
                    title: "Accessibility",
                    isGranted: controller.hasAccessibilityPermission
                )
                permissionRow(
                    title: "Input Monitoring",
                    isGranted: controller.hasInputMonitoringPermission
                )
            }

            if !controller.hasAccessibilityPermission || !controller.hasInputMonitoringPermission {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Grant Accessibility Access") {
                        controller.requestAccessibilityPermission()
                    }
                    .disabled(controller.hasAccessibilityPermission)

                    Button("Grant Input Monitoring Access") {
                        controller.requestInputMonitoringPermission()
                    }
                    .disabled(controller.hasInputMonitoringPermission)

                    Text("After changing either switch in System Settings, click Refresh Access. If it still shows missing, quit and run make run again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(
                "Play keystrokes",
                isOn: Binding(
                    get: { controller.isEnabled },
                    set: { controller.setEnabled($0) }
                )
            )
            .disabled(!controller.canListenForKeystrokes)

            if let lastError = controller.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(20)
        .frame(width: 390)
    }

    private func permissionRow(title: String, isGranted: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isGranted ? Color.green : Color.red)
            Text("\(title): \(isGranted ? "Granted" : "Missing")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
