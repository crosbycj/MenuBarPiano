# MenuBar Piano

A tiny macOS 14+ menu bar app that turns system-wide keystrokes into a looping melody.

## Build

Open `MenuBarPiano.xcodeproj` in Xcode, or build from the terminal with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project MenuBarPiano.xcodeproj -scheme MenuBarPiano -configuration Debug build
```

## Accessibility

The app uses a non-consuming `CGEvent` tap, so typed keys keep going to the active app. macOS requires the built app to be granted Accessibility access in System Settings before the tap can observe key presses.

The app is intentionally not sandboxed. Current Apple guidance says Accessibility access is controlled by System Settings and sandboxed apps cannot use those APIs reliably.
