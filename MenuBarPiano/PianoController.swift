import AppKit
import ApplicationServices
import Combine
import Foundation

final class PianoController: ObservableObject {
    let songs = Song.library

    @Published private(set) var isEnabled = false
    @Published private(set) var hasAccessibilityPermission = AccessibilityPermission.isGranted
    @Published private(set) var lastError: String?
    @Published var selectedSong: Song = Song.library[0] {
        didSet {
            currentNoteIndex = 0
        }
    }

    private let audioEngine = PianoAudioEngine()
    private let keyTap = GlobalKeyTap()
    private var currentNoteIndex = 0

    init() {
        keyTap.onKeyDown = { [weak self] in
            DispatchQueue.main.async {
                self?.playNextNote()
            }
        }
    }

    deinit {
        keyTap.stop()
        audioEngine.stop()
    }

    func select(_ song: Song) {
        selectedSong = song
    }

    func setEnabled(_ enabled: Bool) {
        enabled ? enable() : disable()
    }

    func refreshAccessibilityPermission() {
        hasAccessibilityPermission = AccessibilityPermission.isGranted

        if !hasAccessibilityPermission, isEnabled {
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

    private func enable() {
        refreshAccessibilityPermission()

        guard hasAccessibilityPermission else {
            lastError = "Accessibility access is required before listening to keystrokes."
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
        isEnabled = false
    }

    private func playNextNote() {
        guard isEnabled, !selectedSong.notes.isEmpty else {
            return
        }

        let note = selectedSong.notes[currentNoteIndex % selectedSong.notes.count]
        currentNoteIndex = (currentNoteIndex + 1) % selectedSong.notes.count
        audioEngine.play(midiNote: note)
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
