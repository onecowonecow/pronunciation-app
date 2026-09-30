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
