import Foundation

enum NoteNameParser {
    static func notes(in contents: String) -> [UInt8] {
        contents
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }
            .flatMap { line in
                line.split(whereSeparator: \Character.isWhitespace).compactMap { midiNote(named: $0) }
            }
    }

    static func midiNote<S: StringProtocol>(named token: S) -> UInt8? {
        let characters = Array(token.uppercased())
        guard let letter = characters.first else { return nil }

        let naturalSemitone: Int
        switch letter {
        case "C": naturalSemitone = 0
        case "D": naturalSemitone = 2
        case "E": naturalSemitone = 4
        case "F": naturalSemitone = 5
        case "G": naturalSemitone = 7
        case "A": naturalSemitone = 9
        case "B": naturalSemitone = 11
        default: return nil
        }

        var accidental = 0
        var octaveStart = 1
        if characters.count > 1 {
            if characters[1] == "#" {
                accidental = 1
                octaveStart = 2
            } else if characters[1] == "B" {
                accidental = -1
                octaveStart = 2
            }
        }

        guard
            octaveStart < characters.count,
            let octave = Int(String(characters[octaveStart...])),
            (0...127).contains((octave + 1) * 12 + naturalSemitone + accidental)
        else {
            return nil
        }

        return UInt8((octave + 1) * 12 + naturalSemitone + accidental)
    }
}

enum UserSongLibrary {
    static var songsDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MenuBarPiano", isDirectory: true)
            .appendingPathComponent("Songs", isDirectory: true)
    }

    static func loadSongs(from directory: URL = songsDirectory) -> [Song] {
        let fileManager = FileManager.default
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension.caseInsensitiveCompare("txt") == .orderedSame }
            .compactMap { url -> Song? in
                guard
                    (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                    let contents = try? String(contentsOf: url, encoding: .utf8)
                else {
                    return nil
                }

                let notes = NoteNameParser.notes(in: contents)
                guard !notes.isEmpty else { return nil }

                return Song(
                    id: "user:\(url.standardizedFileURL.path)",
                    name: url.deletingPathExtension().lastPathComponent,
                    category: Song.Category.yourSongs,
                    notes: notes
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func createDirectory() throws {
        try FileManager.default.createDirectory(
            at: songsDirectory,
            withIntermediateDirectories: true
        )
    }
}
