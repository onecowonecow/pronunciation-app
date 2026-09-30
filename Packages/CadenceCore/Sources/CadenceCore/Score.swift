import Foundation

/// Pure scoring helpers shared by UI and tests. No UIKit/SwiftUI imports.
public enum ScoreBand: Equatable {
    case dim, warming, bright, luminous

    public init(score: Double) {
        switch score {
        case ..<50: self = .dim
        case ..<75: self = .warming
        case ..<90: self = .bright
        default: self = .luminous
        }
    }
}

public enum Score {
    /// Clamp any Azure value to 0...100.
    public static func clamp(_ value: Double) -> Double { min(100, max(0, value)) }

    /// Fraction 0...1 used to fill the score ring.
    public static func ringFraction(_ score: Double) -> Double { clamp(score) / 100 }

    /// Words scoring below this go to the Word Bank.
    public static let weakWordThreshold = 80.0
    public static func isWeak(_ accuracy: Double) -> Bool { accuracy < weakWordThreshold }
}
