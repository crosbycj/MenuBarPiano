import Foundation

struct Song: Identifiable, Hashable {
    var id: String { name }

    let name: String
    let notes: [UInt8]
}

extension Song {
    static let library: [Song] = [
        Song(
            name: "Twinkle Twinkle Little Star",
            notes: [
                Note.c4, Note.c4, Note.g4, Note.g4, Note.a4, Note.a4, Note.g4,
                Note.f4, Note.f4, Note.e4, Note.e4, Note.d4, Note.d4, Note.c4,
                Note.g4, Note.g4, Note.f4, Note.f4, Note.e4, Note.e4, Note.d4,
                Note.g4, Note.g4, Note.f4, Note.f4, Note.e4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.g4, Note.g4, Note.a4, Note.a4, Note.g4,
                Note.f4, Note.f4, Note.e4, Note.e4, Note.d4, Note.d4, Note.c4
            ]
        ),
        Song(
            name: "Ode to Joy",
            notes: [
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.e4, Note.d4, Note.d4,
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.d4, Note.c4, Note.c4,
                Note.d4, Note.d4, Note.e4, Note.c4, Note.d4, Note.e4, Note.f4, Note.e4, Note.c4,
                Note.d4, Note.e4, Note.f4, Note.e4, Note.d4, Note.c4, Note.d4, Note.g4,
                Note.e4, Note.e4, Note.f4, Note.g4, Note.g4, Note.f4, Note.e4, Note.d4,
                Note.c4, Note.c4, Note.d4, Note.e4, Note.d4, Note.c4, Note.c4
            ]
        ),
        Song(
            name: "Mary Had a Little Lamb",
            notes: [
                Note.e4, Note.d4, Note.c4, Note.d4, Note.e4, Note.e4, Note.e4,
                Note.d4, Note.d4, Note.d4, Note.e4, Note.g4, Note.g4,
                Note.e4, Note.d4, Note.c4, Note.d4, Note.e4, Note.e4, Note.e4, Note.e4,
                Note.d4, Note.d4, Note.e4, Note.d4, Note.c4
            ]
        )
    ]

    private enum Note {
        static let c4: UInt8 = 60
        static let d4: UInt8 = 62
        static let e4: UInt8 = 64
        static let f4: UInt8 = 65
        static let g4: UInt8 = 67
        static let a4: UInt8 = 69
    }
}
