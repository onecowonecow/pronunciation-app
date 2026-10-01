import XCTest
@testable import CadenceCore

final class CadenceCoreTests: XCTestCase {
    func testBands() {
        XCTAssertEqual(ScoreBand(score: 10), .dim)
        XCTAssertEqual(ScoreBand(score: 50), .warming)
        XCTAssertEqual(ScoreBand(score: 89.9), .bright)
        XCTAssertEqual(ScoreBand(score: 90), .luminous)
    }
    func testClampAndRing() {
        XCTAssertEqual(Score.clamp(120), 100)
        XCTAssertEqual(Score.clamp(-5), 0)
        XCTAssertEqual(Score.ringFraction(50), 0.5)
    }
    func testWeak() {
        XCTAssertTrue(Score.isWeak(79.9))
        XCTAssertFalse(Score.isWeak(80))
    }
    func testFreeTier() {
        XCTAssertEqual(FreeTier(wordsUsedToday: 15).wordsRemaining, 5)
        XCTAssertEqual(FreeTier(wordsUsedToday: 15).allowed(requested: 9), 5)
        XCTAssertTrue(FreeTier(wordsUsedToday: 25).isExhausted)
        XCTAssertEqual(FreeTier(wordsUsedToday: -3).wordsRemaining, 20)
    }
}

final class SentencesTests: XCTestCase {
    func testCategoriesOrderedAndUnique() {
        XCTAssertEqual(Sentences.categories, ["everyday", "work", "interview", "exam"])
        XCTAssertEqual(Sentences.inCategory("everyday").count, 2)
    }
}

final class ReminderTests: XCTestCase {
    func testMessages() {
        XCTAssertEqual(Reminder.message(streak: 0, weakWordCount: 0), "Read one sentence aloud and see your score.")
        XCTAssertEqual(Reminder.message(streak: 0, weakWordCount: 1), "1 word is in your Word Bank. Two minutes is enough.")
        XCTAssertEqual(Reminder.message(streak: 0, weakWordCount: 3), "3 words are in your Word Bank. Two minutes is enough.")
        XCTAssertEqual(Reminder.message(streak: 4, weakWordCount: 0), "Keep your 4-day streak going with one sentence.")
        XCTAssertEqual(Reminder.message(streak: 4, weakWordCount: 2), "Day 5 is waiting. 2 words need another look.")
        XCTAssertFalse(Reminder.message(streak: 9, weakWordCount: 9).contains("!"))
    }
    func testClampedTime() {
        XCTAssertTrue(Reminder.clampedTime(hour: 30, minute: -5) == (23, 0))
        XCTAssertTrue(Reminder.clampedTime(hour: 8, minute: 15) == (8, 15))
    }
}
