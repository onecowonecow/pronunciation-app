import Foundation

/// Port of web/logic.js. Keep the two in sync: same rules, same numbers.
public struct WordResult: Equatable {
    public let word: String
    public let heard: String?
    public let accuracy: Int
}

public struct AttemptScore: Equatable {
    public let overall: Int
    public let accuracy: Int
    public let completeness: Int
    public let fluency: Int?
    public let words: [WordResult]
}

public enum Alignment {
    public static func normalize(_ s: String) -> [String] {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789'- ")
        let cleaned = String(s.lowercased().map { allowed.contains($0) ? $0 : " " })
        return cleaned.split(whereSeparator: { $0 == " " }).map(String.init)
    }

    public static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var cur = [i]
            for j in 1...b.count {
                cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)))
            }
            prev = cur
        }
        return prev[b.count]
    }

    /// 100 for an exact match; any different recognised word is capped below the weak threshold.
    public static func wordSimilarity(_ a: String, _ b: String) -> Int {
        if a == b { return 100 }
        let ca = Array(a), cb = Array(b)
        let longest = max(ca.count, cb.count)
        let raw = longest == 0 ? 100 : Int(((1 - Double(levenshtein(ca, cb)) / Double(longest)) * 100).rounded())
        return min(Int(Score.weakWordThreshold) - 1, raw)
    }

    public static func alignWords(reference: String, heard: String) -> [WordResult] {
        let r = normalize(reference), h = normalize(heard)
        let gap = 1.0
        func cost(_ i: Int, _ j: Int) -> Double { 1 - Double(wordSimilarity(r[i], h[j])) / 100 }
        var d = Array(repeating: Array(repeating: 0.0, count: h.count + 1), count: r.count + 1)
        if r.isEmpty { return [] }
        for i in 1...r.count { d[i][0] = Double(i) * gap }
        if !h.isEmpty { for j in 1...h.count { d[0][j] = Double(j) * gap } }
        if !h.isEmpty {
            for i in 1...r.count {
                for j in 1...h.count {
                    d[i][j] = min(d[i - 1][j - 1] + cost(i - 1, j - 1), d[i - 1][j] + gap, d[i][j - 1] + gap)
                }
            }
        }
        var out: [WordResult] = []
        var i = r.count, j = h.count
        while i > 0 {
            if j > 0 && abs(d[i][j] - (d[i - 1][j - 1] + cost(i - 1, j - 1))) < 1e-9 {
                out.insert(WordResult(word: r[i - 1], heard: h[j - 1], accuracy: wordSimilarity(r[i - 1], h[j - 1])), at: 0)
                i -= 1; j -= 1
            } else if abs(d[i][j] - (d[i - 1][j] + gap)) < 1e-9 {
                out.insert(WordResult(word: r[i - 1], heard: nil, accuracy: 0), at: 0)
                i -= 1
            } else {
                j -= 1
            }
        }
        return out
    }

    /// `confidence` 0...1 from the recogniser, `seconds` speaking time; both optional.
    public static func score(reference: String, heard: String, confidence: Double? = nil, seconds: Double? = nil) -> AttemptScore {
        let words = alignWords(reference: reference, heard: heard)
        guard !words.isEmpty else { return AttemptScore(overall: 0, accuracy: 0, completeness: 0, fluency: nil, words: words) }
        let n = Double(words.count)
        let accuracy = Double(words.reduce(0) { $0 + $1.accuracy }) / n
        let completeness = Double(words.filter { $0.heard != nil }.count) / n * 100
        var fluency: Double?
        if let s = seconds, s > 0 {
            let wpm = n / s * 60
            fluency = Score.clamp(wpm < 90 ? 100 - (90 - wpm) * 1.2 : wpm > 180 ? 100 - (wpm - 180) * 1.2 : 100)
        }
        let conf = confidence.map { Score.clamp($0 * 100) }
        let overall = accuracy * 0.6 + completeness * 0.2 + (fluency ?? accuracy) * 0.1 + (conf ?? accuracy) * 0.1
        return AttemptScore(overall: Int(Score.clamp(overall).rounded()), accuracy: Int(accuracy.rounded()),
                            completeness: Int(completeness.rounded()), fluency: fluency.map { Int($0.rounded()) }, words: words)
    }
}
