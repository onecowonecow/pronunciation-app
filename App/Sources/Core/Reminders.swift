import Foundation
import UserNotifications
import CadenceCore

/// Local daily practice reminder. No server, no push.
enum Reminders {
    private static let id = "daily-practice"

    static func enable(hour: Int, minute: Int, streak: Int, weakWords: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return false }
        let t = Reminder.clampedTime(hour: hour, minute: minute)
        let content = UNMutableNotificationContent()
        content.title = "Cadence"
        content.body = Reminder.message(streak: streak, weakWordCount: weakWords)
        content.sound = .default
        var when = DateComponents(); when.hour = t.hour; when.minute = t.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        do { try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)); return true }
        catch { return false }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
