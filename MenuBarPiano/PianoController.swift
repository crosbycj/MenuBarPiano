import AppKit
import Combine
import CoreGraphics
import Foundation

enum PlaybackMode: Hashable {
    case freePlay
    case song(Song)

    static let freePlayID = "free-play"

    var id: String {
        switch self {
        case .freePlay:
            return Self.freePlayID
        case .song(let song):
            return song.id
        }
    }
}

final class PianoController: ObservableObject {
    let songs = Song.library

    @Published private(set) var isEnabled = false
    @Published private(set) var hasInputMonitoringPermission = InputMonitoringPermission.isGranted
    @Published private(set) var lastError: String?
    @Published private(set) var loopEnabled = true
    @Published private(set) var resetAfterPauseEnabled = true
    @Published private(set) var userSongs: [Song]
    @Published private(set) var selectedMode: PlaybackMode

    var allSongs: [Song] {
        songs + userSongs
    }

    var selectedScript: String? {
        guard case .song(let song) = selectedMode else { return nil }
        return song.script
    }

    var canListenForKeystrokes: Bool {
        hasInputMonitoringPermission
    }

    private static let selectedModeDefaultsKey = "selectedPlaybackModeID"
    private static let inputMonitoringError = "Input Monitoring access is required before listening to keystrokes."

    private let audioEngine = PianoAudioEngine()
    private let keyTap = GlobalKeyTap()
    private let defaults: UserDefaults
    private var currentNoteIndex = 0
    private var freePlayGenerator = FreePlayNoteGenerator()
    private var idleResetTimer: Timer?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let loadedUserSongs = UserSongLibrary.loadSongs()
        userSongs = loadedUserSongs

        let savedID = defaults.string(forKey: Self.selectedModeDefaultsKey)
        if let savedID, let song = (Song.library + loadedUserSongs).first(where: { $0.id == savedID }) {
            selectedMode = .song(song)
        } else {
            selectedMode = .freePlay
            if savedID != nil, savedID != PlaybackMode.freePlayID {
                defaults.set(PlaybackMode.freePlayID, forKey: Self.selectedModeDefaultsKey)
            }
        }

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
        setSelectedMode(.song(song))
    }

    func selectFreePlay() {
        setSelectedMode(.freePlay)
    }

    func reloadUserSongs() {
        let loadedSongs = UserSongLibrary.loadSongs()
        userSongs = loadedSongs

        guard case .song(let selectedSong) = selectedMode,
              selectedSong.category == Song.Category.yourSongs else {
            return
        }

        guard let updatedSong = loadedSongs.first(where: { $0.id == selectedSong.id }) else {
            setSelectedMode(.freePlay)
            return
        }

        if updatedSong != selectedSong {
            selectedMode = .song(updatedSong)
            resetProgress()
        }
    }

    func setEnabled(_ enabled: Bool) {
        enabled ? enable() : disable()
    }

    func toggleLoop() {
        loopEnabled.toggle()

        if case .song(let song) = selectedMode,
           loopEnabled,
           currentNoteIndex >= song.notes.count {
            currentNoteIndex = 0
        }
    }

    func toggleResetAfterPause() {
        resetAfterPauseEnabled.toggle()

        if !resetAfterPauseEnabled {
            cancelIdleResetTimer()
        }
    }

    func refreshPermissions() {
        hasInputMonitoringPermission = InputMonitoringPermission.isGranted

        if hasInputMonitoringPermission, lastError == Self.inputMonitoringError {
            lastError = nil
        }

        if !canListenForKeystrokes, isEnabled {
            disable()
        }
    }

    func requestInputMonitoringPermission() {
        hasInputMonitoringPermission = InputMonitoringPermission.request()
        InputMonitoringPermission.openSettings()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshPermissions()
        }
    }

    private func setSelectedMode(_ mode: PlaybackMode) {
        guard selectedMode != mode else { return }

        selectedMode = mode
        defaults.set(mode.id, forKey: Self.selectedModeDefaultsKey)
        cancelIdleResetTimer()
        resetProgress()
    }

    private func enable() {
        refreshPermissions()

        guard hasInputMonitoringPermission else {
            lastError = Self.inputMonitoringError
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
        guard isEnabled else { return }

        playNextNote()
        restartIdleResetTimer()
    }

    private func playNextNote() {
        switch selectedMode {
        case .freePlay:
            audioEngine.play(midiNote: freePlayGenerator.nextNote())

        case .song(let song):
            guard !song.notes.isEmpty else { return }

            if currentNoteIndex >= song.notes.count {
                guard loopEnabled else { return }
                currentNoteIndex = 0
            }

            audioEngine.play(midiNote: song.notes[currentNoteIndex])
            currentNoteIndex += 1

            if loopEnabled, currentNoteIndex >= song.notes.count {
                currentNoteIndex = 0
            }
        }
    }

    private func restartIdleResetTimer() {
        cancelIdleResetTimer()

        guard resetAfterPauseEnabled else { return }

        let timer = Timer(timeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.resetProgress()
            self?.idleResetTimer = nil
        }

        idleResetTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func resetProgress() {
        currentNoteIndex = 0
        freePlayGenerator.reset()
    }

    private func cancelIdleResetTimer() {
        idleResetTimer?.invalidate()
        idleResetTimer = nil
    }
}

enum InputMonitoringPermission {
    static var isGranted: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    static func request() -> Bool {
        CGRequestListenEventAccess()
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
