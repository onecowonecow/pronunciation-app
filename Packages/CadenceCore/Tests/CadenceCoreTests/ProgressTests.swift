import XCTest
@testable import CadenceCore

final class ProgressTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }()
    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter(); return f.date(from: s)!
    }

    func testXp() {
        XCTAssertEqual(ProgressLog.xp(wordCount: 0, overall: 100), 0)
        XCTAssertEqual(ProgressLog.xp(wordCount: 10, overall: 70), 10)
        XCTAssertEqual(ProgressLog.xp(wordCount: 10, overall: 85), 13)
        XCTAssertEqual(ProgressLog.xp(wordCount: 10, overall: 95), 15)
    }

    func testWeakWordsEnterBankAndStrongDoNot() {
        var log = ProgressLog()
        let r = Alignment.score(reference: "I think so", heard: "I sink so")
        log.record(r, reference: "I think so", scoredCount: 3, at: date("2026-09-30T12:00:00Z"), calendar: cal)
        XCTAssertEqual(log.bank.keys.sorted(), ["think"])
        XCTAssertEqual(log.bank["think"]?.mastery, 0)
        XCTAssertEqual(log.history.count, 1)
    }

    func testMasteryProgressAndGraduation() {
        var log = ProgressLog()
        let weak = Alignment.score(reference: "think", heard: "sink")
        let good = Alignment.score(reference: "think", heard: "think")
        log.record(weak, reference: "think", scoredCount: 1, calendar: cal)
        for _ in 0..<4 { log.record(good, reference: "think", scoredCount: 1, calendar: cal) }
        XCTAssertEqual(log.bank["think"]?.mastery, 4)
        log.record(good, reference: "think", scoredCount: 1, calendar: cal)
        XCTAssertNil(log.bank["think"], "mastery 5 graduates the word")
    }

    func testScoredCountLimitsBankAndXp() {
        var log = ProgressLog()
        let r = Alignment.score(reference: "think thin", heard: "sink sin")
        log.record(r, reference: "think thin", scoredCount: 1, at: date("2026-09-30T12:00:00Z"), calendar: cal)
        XCTAssertEqual(log.bank.count, 1)
        XCTAssertEqual(log.xp(inWeekOf: date("2026-09-30T12:00:00Z"), calendar: cal), 1)
    }

    func testWeekBoundaryIsMonday() {
        var log = ProgressLog()
        let r = Alignment.score(reference: "hello", heard: "hello")
        log.record(r, reference: "hello", scoredCount: 1, at: date("2026-09-27T12:00:00Z"), calendar: cal) // Sunday
        log.record(r, reference: "hello", scoredCount: 1, at: date("2026-09-28T12:00:00Z"), calendar: cal) // Monday
        // A perfect one-word read earns 1 + ceil(0.5) bonus = 2 XP.
        XCTAssertEqual(log.xp(inWeekOf: date("2026-09-27T12:00:00Z"), calendar: cal), 2, "Sunday belongs to the prior week")
        XCTAssertEqual(log.xp(inWeekOf: date("2026-09-30T12:00:00Z"), calendar: cal), 2, "Monday starts a new week")
        XCTAssertEqual(log.xpByWeek.count, 2)
    }

    func testStreak() {
        var log = ProgressLog()
        let r = Alignment.score(reference: "hello", heard: "hello")
        for d in ["2026-09-28T09:00:00Z", "2026-09-29T09:00:00Z", "2026-09-30T09:00:00Z"] {
            log.record(r, reference: "hello", scoredCount: 1, at: date(d), calendar: cal)
        }
        XCTAssertEqual(log.streak(asOf: date("2026-09-30T20:00:00Z"), calendar: cal), 3)
        XCTAssertEqual(log.streak(asOf: date("2026-10-01T08:00:00Z"), calendar: cal), 3, "yesterday still counts")
        XCTAssertEqual(log.streak(asOf: date("2026-10-02T08:00:00Z"), calendar: cal), 0)
    }

    func testCodableRoundTrip() throws {
        var log = ProgressLog()
        log.record(Alignment.score(reference: "think", heard: "sink"), reference: "think", scoredCount: 1, calendar: cal)
        let data = try JSONEncoder().encode(log)
        XCTAssertEqual(try JSONDecoder().decode(ProgressLog.self, from: data), log)
    }
}
