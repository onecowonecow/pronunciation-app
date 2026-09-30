import XCTest
@testable import CadenceCore

private struct FakeError: Error {}

private final class FakeRecognizer: SpeechRecognizing {
    var result: Recognition
    var failStart = false
    init(_ r: Recognition) { result = r }
    func start() async throws { if failStart { throw FakeError() } }
    func stop() async throws -> Recognition { result }
}

final class PracticeSessionTests: XCTestCase {
    private let ref = "I think so"

    func testScoresAndCountsWords() async {
        let s = PracticeSession(reference: ref, recognizer: FakeRecognizer(.init(transcript: "i think so", seconds: 2)),
                                wordsUsedToday: 0, isPremium: false)
        await s.begin(); XCTAssertEqual(s.state, .listening)
        await s.finish()
        guard case let .scored(r, limited) = s.state else { return XCTFail("expected scored") }
        XCTAssertEqual(r.overall, 100); XCTAssertFalse(limited)
        XCTAssertEqual(s.wordsUsedToday, 3)
    }

    func testFreeCapTruncates() async {
        let s = PracticeSession(reference: ref, recognizer: FakeRecognizer(.init(transcript: "i think so", seconds: 2)),
                                wordsUsedToday: 18, isPremium: false)
        await s.begin(); await s.finish()
        guard case let .scored(_, limited) = s.state else { return XCTFail("expected scored") }
        XCTAssertTrue(limited); XCTAssertEqual(s.wordsUsedToday, 20)
    }

    func testCapReachedBlocksStart() async {
        let s = PracticeSession(reference: ref, recognizer: FakeRecognizer(.init(transcript: "x", seconds: 1)),
                                wordsUsedToday: 20, isPremium: false)
        await s.begin(); XCTAssertEqual(s.state, .capReached)
    }

    func testPremiumIgnoresCap() async {
        let s = PracticeSession(reference: ref, recognizer: FakeRecognizer(.init(transcript: "i think so", seconds: 2)),
                                wordsUsedToday: 500, isPremium: true)
        await s.begin(); await s.finish()
        guard case let .scored(_, limited) = s.state else { return XCTFail("expected scored") }
        XCTAssertFalse(limited)
    }

    func testNothingHeardAndFailure() async {
        let quiet = PracticeSession(reference: ref, recognizer: FakeRecognizer(.init(transcript: "  ", seconds: 1)),
                                    wordsUsedToday: 0, isPremium: false)
        await quiet.begin(); await quiet.finish(); XCTAssertEqual(quiet.state, .nothingHeard)

        let bad = FakeRecognizer(.init(transcript: "a", seconds: 1)); bad.failStart = true
        let s = PracticeSession(reference: ref, recognizer: bad, wordsUsedToday: 0, isPremium: false)
        await s.begin()
        if case .failed = s.state {} else { XCTFail("expected failed") }
    }
}
