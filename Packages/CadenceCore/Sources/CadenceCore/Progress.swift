import Foundation

public struct AttemptRecord: Codable, Equatable {
    public let date: Date
    public let reference: String
    public let overall: Int
    public let accuracy: Int
    public let completeness: Int
    public let fluency: Int?
    public init(date: Date, reference: String, overall: Int, accuracy: Int, completeness: Int, fluency: Int?) {
        self.date = date; self.reference = reference; self.overall = overall
        self.accuracy = accuracy; self.completeness = completeness; self.fluency = fluency
    }
}

public struct WordBankEntry: Codable, Equatable {
    public var mastery: Int
    public var lastScore: Int
}

/// Local progress (history, word bank, XP). Mirrors the web prototype; later synced via save-attempt.
public struct ProgressLog: Codable, Equatable {
    public private(set) var history: [AttemptRecord] = []
    public private(set) var bank: [String: WordBankEntry] = [:]
    public private(set) var xpByWeek: [String: Int] = [:]

    public init() {}

    public static func xp(wordCount: Int, overall: Int) -> Int {
        guard wordCount > 0 else { return 0 }
        let bonus = overall >= 90 ? Int((Double(wordCount) * 0.5).rounded(.up))
                  : overall >= 80 ? Int((Double(wordCount) * 0.25).rounded(.up)) : 0
        return wordCount + bonus
    }

    static func updatedMastery(_ m: Int, accuracy: Int) -> Int {
        Double(accuracy) >= Score.weakWordThreshold ? min(5, m + 1) : max(0, m - 1)
    }

    /// Record an attempt. `scoredCount` limits how many words count (free-tier truncation).
    public mutating func record(_ result: AttemptScore, reference: String, scoredCount: Int,
                                at date: Date = Date(), calendar: Calendar = .current) {
        history.append(AttemptRecord(date: date, reference: reference, overall: result.overall,
                                     accuracy: result.accuracy, completeness: result.completeness, fluency: result.fluency))
        let key = Self.weekKey(date, calendar)
        xpByWeek[key, default: 0] += Self.xp(wordCount: scoredCount, overall: result.overall)
        for w in result.words.prefix(scoredCount) {
            if let cur = bank[w.word] {
                let m = Self.updatedMastery(cur.mastery, accuracy: w.accuracy)
                if m >= 5 { bank[w.word] = nil } else { bank[w.word] = WordBankEntry(mastery: m, lastScore: w.accuracy) }
            } else if Score.isWeak(Double(w.accuracy)) {
                bank[w.word] = WordBankEntry(mastery: 0, lastScore: w.accuracy)
            }
        }
    }

    public func xp(inWeekOf date: Date, calendar: Calendar = .current) -> Int {
        xpByWeek[Self.weekKey(date, calendar)] ?? 0
    }

    /// Consecutive days with at least one attempt, ending today (or yesterday if nothing yet today).
    public func streak(asOf now: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = Set(history.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var n = 0
        while days.contains(day) { n += 1; day = calendar.date(byAdding: .day, value: -1, to: day)! }
        return n
    }

    /// Weakest words first.
    public var bankSorted: [(word: String, entry: WordBankEntry)] {
        bank.map { ($0.key, $0.value) }.sorted { $0.entry.lastScore < $1.entry.lastScore }
    }

    /// Monday of the week, yyyy-MM-dd. Computed from the weekday number so it doesn't depend on
    /// Calendar.firstWeekday handling (swift-corelibs on Linux ignores it in dateInterval).
    static func weekKey(_ date: Date, _ calendar: Calendar) -> String {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        let sinceMonday = (weekday + 5) % 7
        let day = calendar.startOfDay(for: date)
        let monday = calendar.date(byAdding: .day, value: -sinceMonday, to: day) ?? day
        let c = calendar.dateComponents([.year, .month, .day], from: monday)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
