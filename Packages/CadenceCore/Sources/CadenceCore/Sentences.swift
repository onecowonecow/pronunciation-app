import Foundation

public struct Sentence: Equatable, Hashable {
    public let category: String
    public let text: String
}

/// Scripted practice lines. Mirrors SENTENCES in web/logic.js.
public enum Sentences {
    public static let all: [Sentence] = [
        .init(category: "everyday", text: "I think the weather is lovely this morning."),
        .init(category: "everyday", text: "Could you please repeat that more slowly?"),
        .init(category: "work", text: "Let's schedule a meeting to review the quarterly results."),
        .init(category: "work", text: "I would like to thank everyone for their thoughtful feedback."),
        .init(category: "interview", text: "My greatest strength is solving difficult problems under pressure."),
        .init(category: "exam", text: "Thirty thousand thoughts thrilled the three thin thinkers."),
    ]
    public static var categories: [String] {
        var seen = Set<String>()
        return all.map(\.category).filter { seen.insert($0).inserted }
    }
    public static func inCategory(_ c: String) -> [Sentence] { all.filter { $0.category == c } }
}
