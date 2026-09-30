import Foundation

/// What a speech recogniser hands back. The real implementation (SFSpeechRecognizer now, Azure later)
/// lives in the app target; tests use a fake.
public struct Recognition: Equatable {
    public let transcript: String
    public let confidence: Double?
    public let seconds: Double
    public init(transcript: String, confidence: Double? = nil, seconds: Double) {
        self.transcript = transcript; self.confidence = confidence; self.seconds = seconds
    }
}

public protocol SpeechRecognizing {
    func start() async throws
    func stop() async throws -> Recognition
}

public enum PracticeState: Equatable {
    case idle
    case listening
    case scored(AttemptScore, limited: Bool)
    case capReached
    case nothingHeard
    case failed(String)
}

/// Drives one practice attempt: record → score → apply the free-tier cap.
/// Pure logic; the SwiftUI layer observes `state`.
public final class PracticeSession {
    public private(set) var state: PracticeState = .idle
    public private(set) var wordsUsedToday: Int
    public let reference: String
    public let isPremium: Bool
    private let recognizer: SpeechRecognizing

    public init(reference: String, recognizer: SpeechRecognizing, wordsUsedToday: Int, isPremium: Bool) {
        self.reference = reference; self.recognizer = recognizer
        self.wordsUsedToday = wordsUsedToday; self.isPremium = isPremium
    }

    public var freeTier: FreeTier { FreeTier(wordsUsedToday: wordsUsedToday) }

    public func begin() async {
        guard state != .listening else { return }
        if !isPremium && freeTier.isExhausted { state = .capReached; return }
        do { try await recognizer.start(); state = .listening }
        catch { state = .failed(error.localizedDescription) }
    }

    public func finish() async {
        guard state == .listening else { return }
        do {
            let rec = try await recognizer.stop()
            guard !rec.transcript.trimmingCharacters(in: .whitespaces).isEmpty else { state = .nothingHeard; return }
            let result = Alignment.score(reference: reference, heard: rec.transcript,
                                         confidence: rec.confidence, seconds: rec.seconds)
            let allowed = isPremium ? result.words.count : freeTier.allowed(requested: result.words.count)
            wordsUsedToday += allowed
            state = .scored(result, limited: allowed < result.words.count)
        } catch { state = .failed(error.localizedDescription) }
    }
}
