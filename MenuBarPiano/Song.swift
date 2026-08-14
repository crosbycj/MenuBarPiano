import Foundation

struct Song: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let notes: [UInt8]
    let script: String?

    init(id: String? = nil, name: String, category: String, notes: [UInt8], script: String? = nil) {
        assert(script == nil || script?.count == notes.count, "Song script length must match note count.")

        self.id = id ?? "built-in:\(name)"
        self.name = name
        self.category = category
        self.notes = notes
        self.script = script
    }
}

extension Song {
    enum Category {
        static let melodies = "Melodies"
        static let dramatic = "Dramatic"
        static let games = "Games"
        static let yourSongs = "Your Songs"
    }

    static let library: [Song] = [
        Song(
            name: "Twinkle Twinkle Little Star",
            category: Category.melodies,
            notes: parseNotes("""
                C4 C4 G4 G4 A4 A4 G4 F4 F4 E4 E4 D4 D4 C4
                G4 G4 F4 F4 E4 E4 D4 G4 G4 F4 F4 E4 E4 D4
                C4 C4 G4 G4 A4 A4 G4 F4 F4 E4 E4 D4 D4 C4
                """),
            script: "Twinkle, twinkle little star how I wonder!"
        ),
        Song(
            name: "Ode to Joy",
            category: Category.melodies,
            notes: parseNotes("""
                E4 E4 F4 G4 G4 F4 E4 D4 C4 C4 D4 E4 E4 D4 D4
                E4 E4 F4 G4 G4 F4 E4 D4 C4 C4 D4 E4 D4 C4 C4
                D4 D4 E4 C4 D4 E4 F4 E4 C4 D4 E4 F4 E4 D4 C4 D4 G4
                E4 E4 F4 G4 G4 F4 E4 D4 C4 C4 D4 E4 D4 C4 C4
                """),
            script: "Joyful joyful we adore thee, God of glory, Lord of love, love!"
        ),
        Song(
            name: "Mary Had a Little Lamb",
            category: Category.melodies,
            notes: parseNotes("""
                E4 D4 C4 D4 E4 E4 E4 D4 D4 D4 E4 G4 G4
                E4 D4 C4 D4 E4 E4 E4 E4 D4 D4 E4 D4 C4
                """),
            script: "Mary had a little lamb, la"
        ),
        Song(
            name: "Für Elise",
            category: Category.melodies,
            notes: parseNotes("""
                E5 D#5 E5 D#5 E5 B4 D5 C5 A4 C4 E4 A4 B4 E4 G#4 B4 C5 E4
                E5 D#5 E5 D#5 E5 B4 D5 C5 A4 C4 E4 A4 B4 E4 C5 B4 A4
                """),
            script: "Tiny moonlit keys tumble then wink."
        ),
        Song(
            name: "Amazing Grace",
            category: Category.melodies,
            notes: parseNotes("""
                D4 G4 B4 G4 B4 A4 G4 E4 D4 D4 G4 B4 G4 B4 A4 D5 B4
                D5 B4 D5 B4 G4 D4 E4 G4 G4 E4 D4 D4 G4 B4 G4 B4 A4 G4
                """),
            script: "Amazing grace, how sweet the sound!"
        ),
        Song(
            name: "The Entertainer",
            category: Category.melodies,
            notes: parseNotes("""
                D#4 E4 C5 A4 B4 G4 D#4 E4 C5 A4 B4 G4 E4 G4 B4 A4
                G4 E4 F#4 G4 C5 B4 A4 G4 D#4 E4 C5 A4 B4 G4 E4 D4
                C4 E4 G4 A4 C5 E5 D5 C5 A4 D5 C5 A4 E4 G4 A4 C5
                """)
        ),
        Song(
            name: "Turkish March",
            category: Category.melodies,
            notes: parseNotes("""
                B4 A4 G#4 A4 C5 D5 C5 B4 C5 E5 F5 E5 D#5 E5 B5
                A5 G#5 A5 B5 A5 G#5 A5 E5 C5 A4 B4 C5 D5 C5 B4
                B4 A4 G#4 A4 C5 D5 C5 B4 C5 E5 F5 E5 D#5 E5 B5
                A5 G#5 A5 B5 A5 G#5 A5 E5 C5 B4 A4 G#4 A4
                """)
        ),
        Song(
            name: "Greensleeves",
            category: Category.melodies,
            notes: parseNotes("""
                A3 C4 D4 E4 F4 E4 D4 B3 G3 A3 B3 C4 A3 A3 G#3 A3
                C4 D4 E4 F4 E4 D4 B3 G3 A3 B3 C4 B3 A3 G#3 F#3 G#3
                E4 E4 D4 B3 G3 A3 B3 C4 A3 A3 G#3 A3
                """)
        ),
        Song(
            name: "Canon in D",
            category: Category.melodies,
            notes: parseNotes("""
                F#5 E5 D5 C#5 B4 A4 B4 C#5 F#5 E5 D5 C#5 B4 A4 G4 F#4
                E4 G4 B4 A4 G4 F#4 E4 D4 E4 F#4 G4 A4 F#4 A4 G4 F#4
                E4 D4 C#4 B3 C#4 D4 E4 F#4 G4 A4 B4 C#5 D5
                """)
        ),
        Song(
            name: "Beethoven's 5th Opening",
            category: Category.dramatic,
            notes: parseNotes("""
                G4 G4 G4 Eb4 F4 F4 F4 D4 G3 G3 G3 Eb3 Ab3 Ab3 Ab3 G3
                Eb4 Eb4 Eb4 C4 G3 G3 G3 D3 Ab3 Ab3 Ab3 G3 F4 F4 F4 D4
                G4 G4 F4 Eb4 Eb3 Eb3 F3 G3 G4 G4 F4 Eb4 Eb3 Eb3 F3 G3
                G4 G4 F4 Eb4 G4 C5
                """),
            script: "Four tiny knocks become thunder on the staircase, now."
        ),
        Song(
            name: "In the Hall of the Mountain King",
            category: Category.dramatic,
            notes: parseNotes("""
                B3 C#4 D4 E4 F#4 D4 F#4 A#3 B3 C#4 D4 E4 F#4 D4 F#4 A#3
                B3 C#4 D4 E4 F#4 G4 E4 G4 B4 A4 F#4 D4 F#4 A4
                B3 C#4 D4 E4 F#4 D4 F#4 A#3 B3 C#4 D4 E4 F#4 D4 F#4 A#3
                """)
        ),
        Song(
            name: "Habanera from Carmen",
            category: Category.dramatic,
            notes: parseNotes("""
                D5 C#5 C5 B4 Bb4 A4 G#4 G4 G4 F#4 F4 E4 Eb4 D4 C#4 D4
                F4 E4 Eb4 D4 C#4 C4 B3 C4 D4 C4 B3 Bb3 A3 G#3 A3
                A4 G#4 G4 F#4 F4 E4 Eb4 D4 C#4 D4 F4 E4 D4 C#4 D4
                """)
        ),
        Song(
            name: "Flight of the Bumblebee",
            category: Category.dramatic,
            notes: parseNotes("""
                A4 G#4 G4 F#4 F4 E4 D#4 E4 F4 E4 D#4 E4 F#4 G4 G#4 A4
                G#4 G4 F#4 F4 E4 D#4 D4 C#4 C4 B3 Bb3 A3 G#3 A3 Bb3 B3
                C4 C#4 D4 D#4 E4 F4 F#4 G4 G#4 A4 Bb4 B4 C5 B4 Bb4 A4
                G#4 G4 F#4 F4 E4 D#4 E4 F4 F#4 G4 G#4 A4
                """)
        ),
        Song(
            name: "Tetris Theme (Korobeiniki)",
            category: Category.games,
            notes: parseNotes("""
                E5 B4 C5 D5 C5 B4 A4 A4 C5 E5 D5 C5 B4 C5 D5 E5
                C5 A4 A4 A4 B4 C5 D5 F5 A5 G5 F5 E5 C5 E5 D5 C5
                B4 B4 C5 D5 E5 C5 A4 A4
                """),
            script: "Blocks tumble neatly; fingers dance fast"
        )
    ]

    private static func parseNotes(_ source: String) -> [UInt8] {
        let tokens = source.split(whereSeparator: \Character.isWhitespace)
        let notes = NoteNameParser.notes(in: source)
        precondition(tokens.count == notes.count, "Built-in melody contains an invalid note name.")
        return notes
    }
}
