import AVFoundation
import Foundation

final class PianoAudioEngine {
    private struct Voice {
        var frequency: Double
        var phase: Double = 0
        var envelopeFrame: Int = 0
    }

    private static let maxVoices = 10

    private let engine = AVAudioEngine()
    private let noteLock = NSLock()

    private var sourceNode: AVAudioSourceNode!
    private var pendingNotes: [UInt8] = []
    private var voices: [Voice] = []
    private var sampleRate: Double = 44_100

    private var attackFrames: Int {
        max(1, Int(sampleRate * 0.005))
    }

    private var decayFrames: Int {
        max(1, Int(sampleRate * 0.400))
    }

    private var totalEnvelopeFrames: Int {
        attackFrames + decayFrames
    }

    init() {
        configureEngine()
    }

    deinit {
        stop()
    }

    func start() throws {
        guard !engine.isRunning else { return }
        try engine.start()
    }

    func stop() {
        engine.stop()
        noteLock.lock()
        pendingNotes.removeAll()
        noteLock.unlock()
        voices.removeAll()
    }

    func play(midiNote: UInt8) {
        if !engine.isRunning {
            try? start()
        }

        noteLock.lock()
        pendingNotes.append(midiNote)
        noteLock.unlock()
    }

    private func configureEngine() {
        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        let channelCount = min(max(outputFormat.channelCount, 1), 2)
        sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44_100

        guard let renderFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channelCount
        ) else {
            preconditionFailure("Could not create audio render format")
        }

        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            self.render(frameCount: frameCount, into: audioBufferList)
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: renderFormat)
        engine.prepare()
    }

    private func takePendingNotes() -> [UInt8] {
        noteLock.lock()
        let notes = pendingNotes
        pendingNotes.removeAll(keepingCapacity: true)
        noteLock.unlock()
        return notes
    }

    private func render(
        frameCount: AVAudioFrameCount,
        into audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) {
        for note in takePendingNotes() {
            beginVoice(note: note)
        }

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

        for frame in 0..<Int(frameCount) {
            let sample = nextSample()

            for buffer in buffers {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                    continue
                }

                let channelCount = max(1, Int(buffer.mNumberChannels))
                if channelCount == 1 {
                    data[frame] = sample
                } else {
                    for channel in 0..<channelCount {
                        data[frame * channelCount + channel] = sample
                    }
                }
            }
        }

        voices.removeAll { $0.envelopeFrame >= totalEnvelopeFrames }
    }

    private func beginVoice(note: UInt8) {
        if voices.count >= Self.maxVoices {
            voices.removeFirst()
        }
        voices.append(Voice(frequency: Self.frequency(for: note)))
    }

    private func nextSample() -> Float {
        var mixed: Double = 0

        for index in voices.indices {
            let envelopeFrame = voices[index].envelopeFrame
            guard envelopeFrame < totalEnvelopeFrames else { continue }

            let gain: Double
            if envelopeFrame < attackFrames {
                gain = Double(envelopeFrame + 1) / Double(attackFrames)
            } else {
                let progress = Double(envelopeFrame - attackFrames) / Double(decayFrames)
                gain = max(0, 1 - progress)
            }

            mixed += sin(voices[index].phase) * gain * 0.22

            voices[index].phase += (2 * .pi * voices[index].frequency) / sampleRate
            if voices[index].phase >= 2 * .pi {
                voices[index].phase.formTruncatingRemainder(dividingBy: 2 * .pi)
            }

            voices[index].envelopeFrame += 1
        }

        return Float(max(-1, min(1, mixed)))
    }

    static func frequency(for midiNote: UInt8) -> Double {
        440 * pow(2, (Double(midiNote) - 69) / 12)
    }
}
