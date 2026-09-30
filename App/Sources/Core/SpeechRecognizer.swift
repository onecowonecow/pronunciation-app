import AVFoundation
import Speech
import CadenceCore

enum SpeechError: LocalizedError {
    case notAuthorized, unavailable
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Microphone or speech recognition access is turned off. Enable both in Settings."
        case .unavailable: return "Speech recognition isn't available right now."
        }
    }
}

/// On-device-first SFSpeechRecognizer wrapper. Calls are serial (driven by PracticeSession).
final class SpeechRecognizer: SpeechRecognizing, @unchecked Sendable {
    /// Normalised mic level 0...1, delivered on an audio thread.
    var onLevel: (@Sendable (Double) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var startedAt = Date()
    private var latest: SFSpeechRecognitionResult?
    private var waiter: CheckedContinuation<Recognition, Error>?

    func start() async throws {
        guard let recognizer, recognizer.isAvailable else { throw SpeechError.unavailable }
        let speech = await withCheckedContinuation { c in SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) } }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard speech == .authorized, mic else { throw SpeechError.notAuthorized }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request = req; latest = nil; startedAt = Date()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result { self.latest = result }
            if result?.isFinal == true || error != nil { self.resolve() }
        }

        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            if let ch = buffer.floatChannelData?[0] {
                let n = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<n { sum += ch[i] * ch[i] }
                self?.onLevel?(min(1, Double((sum / Float(max(n, 1))).squareRoot()) * 5))
            }
        }
        engine.prepare()
        try engine.start()
    }

    func stop() async throws -> Recognition {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        onLevel?(0)
        return try await withCheckedThrowingContinuation { c in
            waiter = c
            // Safety net: if the recogniser never reports a final result, use what we have.
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in self?.resolve() }
        }
    }

    private func resolve() {
        guard let c = waiter else { return }
        waiter = nil
        let best = latest?.bestTranscription
        let segs = best?.segments ?? []
        let conf = segs.isEmpty ? nil : Double(segs.map(\.confidence).reduce(0, +)) / Double(segs.count)
        c.resume(returning: Recognition(transcript: best?.formattedString ?? "", confidence: conf,
                                        seconds: Date().timeIntervalSince(startedAt)))
        task = nil; request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
