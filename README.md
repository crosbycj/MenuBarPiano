# MenuBar Piano

A tiny macOS 14+ menu bar app that turns system-wide keystrokes into a piano melody.

When playback is on, each real key press plays the next note of the selected song. The key you press does not matter, and typing still goes to the active app normally.

The app lives entirely in the `♫` menu bar item. Use that menu to start or stop playback, choose Free Play or a song, toggle looping, toggle reset-after-pause, or quit. You can also press `Option+Shift+M` from any app to start or stop playback.

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

MenuBar Piano needs Input Monitoring enabled for `~/Applications/MenuBarPiano.app`.

If it is missing, open the `♫` menu and choose **Needs Input Monitoring — Open System Settings…**. After granting access, open the menu again; the app does not need to be relaunched.

Accessibility access is not required. The app uses a passive event tap: it observes key presses but never changes or consumes them.

## Songs

Free Play is selected on first launch. It generates a constrained walk across three octaves of the C major pentatonic scale, with no stored rhythm.

The public-domain built-in songs are grouped in the menu:

- Melodies: Twinkle Twinkle Little Star, Ode to Joy, Mary Had a Little Lamb, Für Elise, Amazing Grace, The Entertainer, Turkish March, Greensleeves, Canon in D
- Dramatic: Beethoven's 5th Opening, In the Hall of the Mountain King, Habanera from Carmen, Flight of the Bumblebee
- Games: Tetris Theme (Korobeiniki)

## Add your own songs

Choose **Add Songs…** in the `♫` menu, or put `.txt` files directly in:

```text
~/Library/Application Support/MenuBarPiano/Songs/
```

The filename becomes the song title. Write whitespace-separated note names; sharps and flats both work. Lines beginning with `#` are comments, and invalid tokens are ignored.

```text
# My first melody
C4 C4 G4 G4 A4 A4 G4
F4 F4 E4 E4 D4 D4 C4
F#4 Eb5 not-a-note
```

The app rescans this folder whenever you open its menu. A file with no valid notes is omitted.
