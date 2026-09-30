import Foundation

/// Free tier: 20 scored words per local day. Server is authoritative; this drives UI only.
public struct FreeTier: Equatable {
    public static let dailyWordCap = 20

    public let wordsUsedToday: Int
    public init(wordsUsedToday: Int) { self.wordsUsedToday = max(0, wordsUsedToday) }

    public var wordsRemaining: Int { max(0, Self.dailyWordCap - wordsUsedToday) }
    public var isExhausted: Bool { wordsRemaining == 0 }

    /// How many of `requested` words can be scored.
    public func allowed(requested: Int) -> Int { min(max(0, requested), wordsRemaining) }
}
