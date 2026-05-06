import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifier = "tokeroot.daily-reminder"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async -> Bool {
        if authorizationStatus == .notDetermined {
            guard await requestAuthorization() else { return false }
        } else {
            await refreshAuthorizationStatus()
        }

        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return false
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "今日のルート"
        content.body = "今日も5分だけ、できるところから進めましょう。"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
