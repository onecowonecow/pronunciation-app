import XCTest
@testable import CadenceCore

final class AlignmentTests: XCTestCase {
    func testNormalize() { XCTAssertEqual(Alignment.normalize("Hello, World!"), ["hello", "world"]) }

    func testLevenshtein() {
        XCTAssertEqual(Alignment.levenshtein(Array("kitten"), Array("sitting")), 3)
        XCTAssertEqual(Alignment.levenshtein([], Array("abc")), 3)
    }

    func testPerfectRead() {
        let r = Alignment.score(reference: "I think so", heard: "i think so")
        XCTAssertEqual(r.overall, 100)
        XCTAssertEqual(r.completeness, 100)
    }

    func testSubstitutionIsWeak() {
        let r = Alignment.score(reference: "I think so", heard: "I sink so")
        XCTAssertLessThan(r.words[1].accuracy, 80)
        XCTAssertEqual(r.words[1].heard, "sink")
        XCTAssertEqual(r.words[0].accuracy, 100)
    }

    func testMissingWord() {
        let r = Alignment.score(reference: "the quick brown fox", heard: "the brown fox")
        XCTAssertNil(r.words.first { $0.word == "quick" }?.heard)
        XCTAssertEqual(r.completeness, 75)
    }

    func testExtraWordsIgnoredAndEmptyHeard() {
        XCTAssertEqual(Alignment.score(reference: "hello", heard: "uh hello there").words.count, 1)
        XCTAssertEqual(Alignment.score(reference: "hello world", heard: "").overall, 0)
    }

    func testFluency() {
        XCTAssertEqual(Alignment.score(reference: "a b c d e f", heard: "a b c d e f", seconds: 3).fluency, 100)
        XCTAssertLessThan(Alignment.score(reference: "a b c d e f", heard: "a b c d e f", seconds: 20).fluency ?? 100, 60)
    }
}
