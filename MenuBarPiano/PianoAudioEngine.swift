import AVFoundation
import Foundation

final class PianoAudioEngine {
    private let engine = AVAudioEngine()
    private let noteLock = NSLock()

    private var sourceNode: AVAudioSourceNode!
    private var pendingNote: UInt8?
    private var sampleRate: Double = 44_100
    private var phase: Double = 0
    private var frequency: Double = 440
    private var envelopeFrame: Int = Int.max

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
        pendingNote = nil
        noteLock.unlock()
        envelopeFrame = Int.max
    }

    func play(midiNote: UInt8) {
        if !engine.isRunning {
            try? start()
        }

        noteLock.lock()
        pendingNote = midiNote
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

    private func takePendingNote() -> UInt8? {
        noteLock.lock()
        let note = pendingNote
        pendingNote = nil
        noteLock.unlock()
        return note
    }

    private func render(
        frameCount: AVAudioFrameCount,
        into audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) {
        if let note = takePendingNote() {
            begin(note: note)
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
    }

    private func begin(note: UInt8) {
        frequency = Self.frequency(for: note)
        phase = 0
        envelopeFrame = 0
    }

    private func nextSample() -> Float {
        guard envelopeFrame < totalEnvelopeFrames else {
            return 0
        }

        let gain: Double
        if envelopeFrame < attackFrames {
            gain = Double(envelopeFrame + 1) / Double(attackFrames)
        } else {
            let progress = Double(envelopeFrame - attackFrames) / Double(decayFrames)
            gain = max(0, 1 - progress)
        }

        let sample = sin(phase) * gain * 0.22
        phase += (2 * .pi * frequency) / sampleRate

        if phase >= 2 * .pi {
            phase.formTruncatingRemainder(dividingBy: 2 * .pi)
        }

        envelopeFrame += 1
        return Float(sample)
    }

    static func frequency(for midiNote: UInt8) -> Double {
        440 * pow(2, (Double(midiNote) - 69) / 12)
    }
}
