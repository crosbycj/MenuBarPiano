# MenuBar Piano

A tiny macOS 14+ menu bar app that turns system-wide keystrokes into a looping piano melody.

When playback is on, each real key press plays the next note of the selected song. The key you press does not matter, and typing still goes to the active app normally.

## Run

From the project root:

```sh
make run
```

This builds a Release app, installs it to:

```text
~/Applications/MenuBarPiano.app
```

and launches that stable copy. macOS privacy permissions are granted to that installed app, so prefer `make run` over running from Xcode.

If things get weird after code changes:

```sh
make clean && make run
```

To reveal the installed app in Finder:

```sh
make reveal
```

## Permissions

MenuBar Piano needs both macOS permissions enabled for `~/Applications/MenuBarPiano.app`:

- Accessibility
- Input Monitoring

After changing permissions in System Settings, quit and rerun the app, then click `Refresh Access` in the control panel.

## Songs

The built-in melodies are:

- Twinkle Twinkle Little Star
- Ode to Joy
- Mary Had a Little Lamb
