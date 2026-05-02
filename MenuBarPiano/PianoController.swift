import AppKit
import ApplicationServices
import Combine
import Foundation
import IOKit.hidsystem

final class PianoController: ObservableObject {
    let songs = Song.library

    @Published private(set) var isEnabled = false
    @Published private(set) var hasAccessibilityPermission = AccessibilityPermission.isGranted
    @Published private(set) var hasInputMonitoringPermission = InputMonitoringPermission.isGranted
    @Published private(set) var lastError: String?
    @Published private(set) var loopEnabled = true
    @Published private(set) var resetAfterPauseEnabled = true
    @Published var selectedSong: Song = Song.library[0] {
        didSet {
            currentNoteIndex = 0
        }
    }

    private let audioEngine = PianoAudioEngine()
    private let keyTap = GlobalKeyTap()
    private var currentNoteIndex = 0
    private var idleResetTimer: Timer?

    init() {
        keyTap.onKeyDown = { [weak self] in
            DispatchQueue.main.async {
                self?.handleKeyDown()
            }
        }
    }

    deinit {
        cancelIdleResetTimer()
        keyTap.stop()
        audioEngine.stop()
    }

    func select(_ song: Song) {
        selectedSong = song
    }

    func setEnabled(_ enabled: Bool) {
        enabled ? enable() : disable()
    }

    func toggleLoop() {
        loopEnabled.toggle()

        if loopEnabled, currentNoteIndex >= selectedSong.notes.count {
            currentNoteIndex = 0
        }
    }

    func toggleResetAfterPause() {
        resetAfterPauseEnabled.toggle()

        if !resetAfterPauseEnabled {
            cancelIdleResetTimer()
        }
    }

    var canListenForKeystrokes: Bool {
        hasAccessibilityPermission && hasInputMonitoringPermission
    }

    func playPreviewNote() {
        guard let note = selectedSong.notes.first else {
            return
        }

        audioEngine.play(midiNote: note)
    }

    func refreshAccessibilityPermission() {
        refreshPermissions()
    }

    func refreshPermissions() {
        hasAccessibilityPermission = AccessibilityPermission.isGranted
        hasInputMonitoringPermission = InputMonitoringPermission.isGranted

        if !canListenForKeystrokes, isEnabled {
            disable()
        }
    }

    func requestAccessibilityPermission() {
        hasAccessibilityPermission = AccessibilityPermission.request()
        AccessibilityPermission.openSettings()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshAccessibilityPermission()
        }
    }

    func requestInputMonitoringPermission() {
        hasInputMonitoringPermission = InputMonitoringPermission.request()
        InputMonitoringPermission.openSettings()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshPermissions()
        }
    }

    private func enable() {
        refreshPermissions()

        guard hasAccessibilityPermission else {
            lastError = "Accessibility access is required before listening to keystrokes."
            isEnabled = false
            keyTap.stop()
            audioEngine.stop()
            return
        }

        guard hasInputMonitoringPermission else {
            lastError = "Input Monitoring access is required before listening to keystrokes."
            isEnabled = false
            keyTap.stop()
            audioEngine.stop()
            return
        }

        do {
            try audioEngine.start()
        } catch {
            lastError = "Audio could not start: \(error.localizedDescription)"
            isEnabled = false
            return
        }

        guard keyTap.start() else {
            lastError = "Keyboard event tap could not start."
            isEnabled = false
            audioEngine.stop()
            return
        }

        lastError = nil
        isEnabled = true
    }

    private func disable() {
        keyTap.stop()
        audioEngine.stop()
        cancelIdleResetTimer()
        isEnabled = false
    }

    private func handleKeyDown() {
        guard isEnabled else {
            return
        }

        playNextNote()
        restartIdleResetTimer()
    }

    private func playNextNote() {
        let notes = selectedSong.notes

        guard !notes.isEmpty else {
            return
        }

        if currentNoteIndex >= notes.count {
            guard loopEnabled else {
                return
            }

            currentNoteIndex = 0
        }

        let note = notes[currentNoteIndex]
        currentNoteIndex += 1

        if loopEnabled, currentNoteIndex >= notes.count {
            currentNoteIndex = 0
        }

        audioEngine.play(midiNote: note)
    }

    private func restartIdleResetTimer() {
        cancelIdleResetTimer()

        guard resetAfterPauseEnabled else {
            return
        }

        let timer = Timer(timeInterval: 5, repeats: false) { [weak self] _ in
            self?.currentNoteIndex = 0
            self?.idleResetTimer = nil
        }

        idleResetTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func cancelIdleResetTimer() {
        idleResetTimer?.invalidate()
        idleResetTimer = nil
    }
}

enum AccessibilityPermission {
    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func request() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

enum InputMonitoringPermission {
    static var isGranted: Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    @discardableResult
    static func request() -> Bool {
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    static func openSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
