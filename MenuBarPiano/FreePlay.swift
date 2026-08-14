import Foundation

enum FreePlayTuning {
    // C major pentatonic from C3 through C6 (inclusive).
    static let midiNoteRange: ClosedRange<UInt8> = 48...84

    // Relative weights for nearby moves of 1 or 2 pentatonic scale degrees.
    static let stepWeights: [(distance: Int, weight: Double)] = [
        (1, 0.72),
        (2, 0.28)
    ]

    static let leapProbability = 0.10
    static let leapDistanceRange = 3...5
    static let edgeZoneScaleDegrees = 4
    static let centeringStrength = 0.32
}

struct FreePlayNoteGenerator {
    private static let pentatonicPitchClasses: Set<Int> = [0, 2, 4, 7, 9]

    private let notes: [UInt8]
    private var currentIndex: Int

    init() {
        notes = FreePlayTuning.midiNoteRange.filter {
            Self.pentatonicPitchClasses.contains(Int($0) % 12)
        }
        currentIndex = notes.count / 2
    }

    mutating func reset() {
        currentIndex = notes.count / 2
    }

    mutating func nextNote() -> UInt8 {
        let note = notes[currentIndex]
        currentIndex = nextIndex()
        return note
    }

    private mutating func nextIndex() -> Int {
        let distance = randomDistance()
        let center = Double(notes.count - 1) / 2
        let distanceFromCenter = abs(Double(currentIndex) - center)
        let edgeDistance = max(0, distanceFromCenter - (center - Double(FreePlayTuning.edgeZoneScaleDegrees)))
        let edgeProgress = min(1, edgeDistance / Double(FreePlayTuning.edgeZoneScaleDegrees))
        let towardCenterProbability = 0.5 + (FreePlayTuning.centeringStrength * edgeProgress)

        let towardCenterDirection = currentIndex < Int(center) ? 1 : -1
        let direction: Int
        if currentIndex == Int(center), Bool.random() {
            direction = 1
        } else if Double.random(in: 0..<1) < towardCenterProbability {
            direction = towardCenterDirection
        } else {
            direction = -towardCenterDirection
        }

        let candidate = currentIndex + (direction * distance)
        if notes.indices.contains(candidate) {
            return candidate
        }

        // Reflect at the range boundary so an outward choice never repeats the edge note.
        return currentIndex - (direction * distance)
    }

    private func randomDistance() -> Int {
        if Double.random(in: 0..<1) < FreePlayTuning.leapProbability {
            return Int.random(in: FreePlayTuning.leapDistanceRange)
        }

        let totalWeight = FreePlayTuning.stepWeights.reduce(0) { $0 + $1.weight }
        var draw = Double.random(in: 0..<totalWeight)

        for step in FreePlayTuning.stepWeights {
            draw -= step.weight
            if draw <= 0 {
                return step.distance
            }
        }

        return FreePlayTuning.stepWeights.last?.distance ?? 1
    }
}
