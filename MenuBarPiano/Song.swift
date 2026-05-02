import Foundation

struct Song: Identifiable, Hashable {
    var id: String { name }

    let name: String
    let category: String
    let notes: [UInt8]
    let script: String?

    init(name: String, category: String, notes: [UInt8], script: String? = nil) {
        assert(script == nil || script?.count == notes.count, "Song script length must match note count.")

        self.name = name
        self.category = category
        self.notes = notes
        self.script = script
    }
}

extension Song {
    static let library: [Song] = [
        Song(
            name: "Twinkle Twinkle Little Star",
            category: Category.melodies,
            notes: [
                Note.c4, Note.c4, Note.g4, Note.g4, Note.a4, Note.a4, Note.g4,
                Note.f4, Note.f4, Note.e4, Note.e4, Note.d4, Note.d4, Note.c4,
                Note.g4, Note.g4, Note.f4, Note.f4, Note.e4, Note.e4, Note.d4,
                Note.g4, Note.g4, Note.f4, Note.f4, Note.e4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.g4, Note.g4, Note.a4, Note.a4, Note.g4,
                Note.f4, Note.f4, Note.e4, Note.e4, Note.d4, Note.d4, Note.c4
            ],
            script: "Twinkle, twinkle little star how I wonder!"
        ),
        Song(
            name: "Ode to Joy",
            category: Category.melodies,
            notes: [
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.e4, Note.d4, Note.d4,
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.d4, Note.c4, Note.c4,
                Note.d4, Note.d4, Note.e4, Note.c4, Note.d4, Note.e4, Note.f4, Note.e4, Note.c4,
                Note.d4, Note.e4, Note.f4, Note.e4, Note.d4, Note.c4, Note.d4, Note.g4,
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.d4, Note.c4, Note.c4
            ],
            script: "Joyful joyful we adore thee, God of glory, Lord of love, love!"
        ),
        Song(
            name: "Mary Had a Little Lamb",
            category: Category.melodies,
            notes: [
                Note.e4, Note.d4, Note.c4, Note.d4, Note.e4, Note.e4, Note.e4,
                Note.d4, Note.d4, Note.d4, Note.e4, Note.g4, Note.g4,
                Note.e4, Note.d4, Note.c4, Note.d4, Note.e4, Note.e4, Note.e4, Note.e4,
                Note.d4, Note.d4, Note.e4, Note.d4, Note.c4
            ],
            script: "Mary had a little lamb, la"
        ),
        Song(
            name: "Für Elise",
            category: Category.melodies,
            notes: [
                Note.e5, Note.dSharp5, Note.e5, Note.dSharp5, Note.e5, Note.b4, Note.d5, Note.c5, Note.a4,
                Note.c4, Note.e4, Note.a4, Note.b4, Note.e4, Note.gSharp4, Note.b4, Note.c5, Note.e4,
                Note.e5, Note.dSharp5, Note.e5, Note.dSharp5, Note.e5, Note.b4, Note.d5, Note.c5, Note.a4,
                Note.c4, Note.e4, Note.a4, Note.b4, Note.e4, Note.c5, Note.b4, Note.a4
            ],
            script: "Tiny moonlit keys tumble then wink."
        ),
        Song(
            name: "Amazing Grace",
            category: Category.melodies,
            notes: [
                Note.d4, Note.g4, Note.b4, Note.g4, Note.b4, Note.a4, Note.g4, Note.e4, Note.d4,
                Note.d4, Note.g4, Note.b4, Note.g4, Note.b4, Note.a4, Note.d5, Note.b4,
                Note.d5, Note.b4, Note.d5, Note.b4, Note.g4, Note.d4,
                Note.e4, Note.g4, Note.g4, Note.e4, Note.d4, Note.d4,
                Note.g4, Note.b4, Note.g4, Note.b4, Note.a4, Note.g4
            ],
            script: "Amazing grace, how sweet the sound!"
        ),
        Song(
            name: "Jaws Theme",
            category: Category.dramatic,
            notes: [
                Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2,
                Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2,
                Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2, Note.e2, Note.f2,
                Note.e2, Note.f2, Note.e2, Note.f2
            ],
            script: "Tiny shark taps the boat now"
        ),
        Song(
            name: "Imperial March",
            category: Category.dramatic,
            notes: [
                Note.g4, Note.g4, Note.g4, Note.eFlat4, Note.bFlat4, Note.g4, Note.eFlat4, Note.bFlat4, Note.g4,
                Note.d5, Note.d5, Note.d5, Note.eFlat5, Note.bFlat4, Note.gFlat4, Note.eFlat4, Note.bFlat4, Note.g4,
                Note.g5, Note.g4, Note.g4, Note.g5, Note.fSharp5, Note.f5, Note.e5, Note.eFlat5, Note.e5,
                Note.aFlat4, Note.cSharp5, Note.c5, Note.b4, Note.bFlat4, Note.a4, Note.bFlat4,
                Note.eFlat5, Note.gFlat5, Note.bFlat5, Note.g5, Note.bFlat5, Note.d6, Note.g6,
                Note.eFlat5, Note.bFlat4, Note.g4
            ],
            script: "Tiny boots march past moons in strict time!!"
        ),
        Song(
            name: "Pink Panther Theme",
            category: Category.dramatic,
            notes: [
                Note.f4, Note.fSharp4, Note.gSharp4, Note.a4, Note.f4, Note.fSharp4, Note.gSharp4, Note.a4,
                Note.d5, Note.cSharp5, Note.fSharp4, Note.a4, Note.cSharp5, Note.c5, Note.b4, Note.a4,
                Note.fSharp4, Note.e4, Note.fSharp4,
                Note.f4, Note.fSharp4, Note.gSharp4, Note.a4, Note.f4, Note.fSharp4, Note.gSharp4, Note.a4,
                Note.d5, Note.cSharp5, Note.a4, Note.cSharp5, Note.fSharp5, Note.f5
            ],
            script: "A sneaky sax prowls past midnight"
        ),
        Song(
            name: "Psycho Shower Scene",
            category: Category.dramatic,
            notes: [
                Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6,
                Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6,
                Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6, Note.eFlat6, Note.e6,
                Note.eFlat6, Note.e6, Note.eFlat6, Note.e6
            ],
            script: "High strings jab the air now"
        ),
        Song(
            name: "Beethoven's 5th Opening",
            category: Category.dramatic,
            notes: [
                Note.g4, Note.g4, Note.g4, Note.eFlat4, Note.f4, Note.f4, Note.f4, Note.d4,
                Note.g3, Note.g3, Note.g3, Note.eFlat3, Note.aFlat3, Note.aFlat3, Note.aFlat3, Note.g3,
                Note.eFlat4, Note.eFlat4, Note.eFlat4, Note.c4, Note.g3, Note.g3, Note.g3, Note.d3,
                Note.aFlat3, Note.aFlat3, Note.aFlat3, Note.g3, Note.f4, Note.f4, Note.f4, Note.d4,
                Note.g4, Note.g4, Note.f4, Note.eFlat4, Note.eFlat3, Note.eFlat3, Note.f3, Note.g3,
                Note.g4, Note.g4, Note.f4, Note.eFlat4, Note.eFlat3, Note.eFlat3, Note.f3, Note.g3,
                Note.g4, Note.g4, Note.f4, Note.eFlat4, Note.g4, Note.c5
            ],
            script: "Four tiny knocks become thunder on the staircase, now."
        ),
        Song(
            name: "Tetris Theme",
            category: Category.games,
            notes: [
                Note.e5, Note.b4, Note.c5, Note.d5, Note.c5, Note.b4, Note.a4, Note.a4,
                Note.c5, Note.e5, Note.d5, Note.c5, Note.b4, Note.c5, Note.d5, Note.e5,
                Note.c5, Note.a4, Note.a4, Note.a4, Note.b4, Note.c5, Note.d5, Note.f5,
                Note.a5, Note.g5, Note.f5, Note.e5, Note.c5, Note.e5, Note.d5, Note.c5,
                Note.b4, Note.b4, Note.c5, Note.d5, Note.e5, Note.c5, Note.a4, Note.a4
            ],
            script: "Blocks tumble neatly; fingers dance fast"
        ),
        Song(
            name: "Super Mario Bros. Overworld Theme",
            category: Category.games,
            notes: [
                Note.e5, Note.e5, Note.e5, Note.c5, Note.e5, Note.g5, Note.g4,
                Note.c5, Note.g4, Note.e4, Note.a4, Note.b4, Note.bFlat4, Note.a4, Note.g4,
                Note.e5, Note.g5, Note.a5, Note.f5, Note.g5, Note.e5, Note.c5, Note.d5, Note.b4,
                Note.c5, Note.g4, Note.e4, Note.a4, Note.b4, Note.bFlat4, Note.a4, Note.g4,
                Note.e5, Note.g5, Note.a5, Note.f5, Note.g5, Note.e5, Note.c5, Note.d5, Note.b4
            ],
            script: "Jumping plumbers chase coins in sunshine."
        )
    ]

    private enum Category {
        static let melodies = "Melodies"
        static let dramatic = "Dramatic"
        static let games = "Games"
    }

    private enum Note {
        static let e2: UInt8 = 40
        static let f2: UInt8 = 41

        static let d3: UInt8 = 50
        static let dSharp3: UInt8 = 51
        static let eFlat3: UInt8 = dSharp3
        static let f3: UInt8 = 53
        static let g3: UInt8 = 55
        static let gSharp3: UInt8 = 56
        static let aFlat3: UInt8 = gSharp3

        static let c4: UInt8 = 60
        static let d4: UInt8 = 62
        static let dSharp4: UInt8 = 63
        static let eFlat4: UInt8 = dSharp4
        static let e4: UInt8 = 64
        static let f4: UInt8 = 65
        static let fSharp4: UInt8 = 66
        static let gFlat4: UInt8 = fSharp4
        static let g4: UInt8 = 67
        static let gSharp4: UInt8 = 68
        static let aFlat4: UInt8 = gSharp4
        static let a4: UInt8 = 69
        static let aSharp4: UInt8 = 70
        static let bFlat4: UInt8 = aSharp4
        static let b4: UInt8 = 71

        static let c5: UInt8 = 72
        static let cSharp5: UInt8 = 73
        static let dFlat5: UInt8 = cSharp5
        static let d5: UInt8 = 74
        static let dSharp5: UInt8 = 75
        static let eFlat5: UInt8 = dSharp5
        static let e5: UInt8 = 76
        static let f5: UInt8 = 77
        static let fSharp5: UInt8 = 78
        static let gFlat5: UInt8 = fSharp5
        static let g5: UInt8 = 79
        static let gSharp5: UInt8 = 80
        static let aFlat5: UInt8 = gSharp5
        static let a5: UInt8 = 81
        static let aSharp5: UInt8 = 82
        static let bFlat5: UInt8 = aSharp5

        static let d6: UInt8 = 86
        static let dSharp6: UInt8 = 87
        static let eFlat6: UInt8 = dSharp6
        static let e6: UInt8 = 88
        static let g6: UInt8 = 91
    }
}
