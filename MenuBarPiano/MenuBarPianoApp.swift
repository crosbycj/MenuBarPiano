import AppKit
import SwiftUI

@main
struct MenuBarPianoApp: App {
    @StateObject private var controller = PianoController()

    var body: some Scene {
        MenuBarExtra {
            PianoMenuView()
                .environmentObject(controller)
                .onAppear {
                    controller.refreshAccessibilityPermission()
                }
        } label: {
            Label("MenuBar Piano", systemImage: "pianokeys")
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct PianoMenuView: View {
    @EnvironmentObject private var controller: PianoController

    var body: some View {
        Section("Song") {
            ForEach(controller.songs) { song in
                Button {
                    controller.select(song)
                } label: {
                    Label(
                        song.name,
                        systemImage: song == controller.selectedSong ? "checkmark" : "music.note"
                    )
                }
            }
        }

        Divider()

        if !controller.hasAccessibilityPermission {
            Text("Accessibility access required")
            Button("Grant Access") {
                controller.requestAccessibilityPermission()
            }
        }

        Toggle(
            "Play Keystrokes",
            isOn: Binding(
                get: { controller.isEnabled },
                set: { controller.setEnabled($0) }
            )
        )
        .disabled(!controller.hasAccessibilityPermission)

        if let lastError = controller.lastError {
            Text(lastError)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
