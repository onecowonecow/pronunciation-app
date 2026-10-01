import Foundation

/// Copy for the daily practice reminder. Plain and specific; no exclamation marks.
public enum Reminder {
    public static func message(streak: Int, weakWordCount: Int) -> String {
        if streak >= 2 && weakWordCount > 0 {
            return "Day \(streak + 1) is waiting. \(weakWordCount) \(weakWordCount == 1 ? "word needs" : "words need") another look."
        }
        if streak >= 2 {
            return "Keep your \(streak)-day streak going with one sentence."
        }
        if weakWordCount > 0 {
            return "\(weakWordCount) \(weakWordCount == 1 ? "word is" : "words are") in your Word Bank. Two minutes is enough."
        }
        return "Read one sentence aloud and see your score."
    }

    /// Clamp user-chosen reminder time to a valid hour/minute.
    public static func clampedTime(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        (min(23, max(0, hour)), min(59, max(0, minute)))
    }
}
