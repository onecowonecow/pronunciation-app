import Foundation
import CadenceCore

/// Bridges PracticeSession (pure logic) to SwiftUI. Free-tier usage persists per local day.
@MainActor
final class PracticeViewModel: ObservableObject {
    @Published private(set) var state: PracticeState = .idle
    @Published private(set) var level: Double = 0
    @Published var category = Sentences.categories[0] { didSet { index = 0; reset() } }
    @Published private(set) var index = 0

    private let recognizer = SpeechRecognizer()
    private var session: PracticeSession?
    private let defaults = UserDefaults.standard
    var isPremium = false // wired to RevenueCat in M4

    init() {
        recognizer.onLevel = { [weak self] v in Task { @MainActor in self?.level = v } }
        reset()
    }

    var sentences: [Sentence] { Sentences.inCategory(category) }
    var reference: String { sentences[index % sentences.count].text }
    var wordsRemaining: Int { max(0, FreeTier.dailyWordCap - usedToday) }

    private var dayKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return "usage." + f.string(from: Date())
    }
    private var usedToday: Int { defaults.integer(forKey: dayKey) }

    func next() { index += 1; reset() }

    func reset() {
        session = PracticeSession(reference: reference, recognizer: recognizer,
                                  wordsUsedToday: usedToday, isPremium: isPremium)
        state = .idle
    }

    func pressDown() {
        guard let s = session else { return }
        Task { await s.begin(); state = s.state }
    }

    func pressUp() {
        guard let s = session, s.state == .listening else { return }
        Task {
            await s.finish()
            state = s.state
            defaults.set(s.wordsUsedToday, forKey: dayKey)
            objectWillChange.send()
        }
    }
}
