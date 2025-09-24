import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#endif
import Combine

class NotificationService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()

    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        userNotificationCenter.delegate = self
        checkAuthorizationStatus()
        loadNotificationSettings()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])

            await MainActor.run {
                self.isAuthorized = granted
            }

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func registerForRemoteNotifications() async {
        #if os(iOS)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }

    func scheduleTaskReminder(for task: Task) {
        guard let dueDate = task.dueDate,
              notificationSettings.taskReminders else { return }

        let reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate

        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "'\(task.title)' is due in 1 hour"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "task_reminder",
            "taskId": task.id.uuidString
        ]

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule task reminder: \(error)")
            }
        }
    }

    func cancelTaskReminder(for task: Task) {
        let identifier = "task_\(task.id.uuidString)"
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func scheduleMessageNotification(for message: Message) {
        guard notificationSettings.messageNotifications,
              let currentUser = getCurrentUser(),
              message.sender.id != currentUser.id else { return }

        let senderName = message.sender.displayName
        let conversationName = message.conversation.name ?? "Direct Message"

        let content = UNMutableNotificationContent()
        content.title = conversationName
        content.body = "\(senderName): \(message.text)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "new_message",
            "messageId": message.id.uuidString,
            "conversationId": message.conversation.id.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "message_\(message.id.uuidString)",
            content: content,
            trigger: trigger
        )

        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule message notification: \(error)")
            }
        }
    }

    func scheduleMentionNotification(message: Message, mentionedUser: User) {
        guard notificationSettings.mentionNotifications,
              let currentUser = getCurrentUser(),
              mentionedUser.id == currentUser.id else { return }

        let senderName = message.sender.displayName
        let conversationName = message.conversation.name ?? "Direct Message"

        let content = UNMutableNotificationContent()
        content.title = "You were mentioned"
        content.body = "\(senderName) mentioned you in \(conversationName)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "mention",
            "messageId": message.id.uuidString,
            "conversationId": message.conversation.id.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "mention_\(message.id.uuidString)_\(mentionedUser.id.uuidString)",
            content: content,
            trigger: trigger
        )

        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule mention notification: \(error)")
            }
        }
    }

    func scheduleTaskAssignmentNotification(task: Task, assignedUser: User) {
        guard notificationSettings.taskAssignments,
              let currentUser = getCurrentUser(),
              assignedUser.id == currentUser.id else { return }

        let assignerName = task.owner.displayName

        let content = UNMutableNotificationContent()
        content.title = "New Task Assignment"
        content.body = "\(assignerName) assigned '\(task.title)' to you"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "task_assignment",
            "taskId": task.id.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "assignment_\(task.id.uuidString)_\(assignedUser.id.uuidString)",
            content: content,
            trigger: trigger
        )

        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule assignment notification: \(error)")
            }
        }
    }

    func scheduleDailyBriefNotification() {
        guard notificationSettings.dailyBrief,
              let briefTime = notificationSettings.briefTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Brief Ready"
        content.body = "Your AI-generated daily brief is ready to view"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "daily_brief"
        ]

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: briefTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_brief",
            content: content,
            trigger: trigger
        )

        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule daily brief notification: \(error)")
            }
        }
    }

    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        saveNotificationSettings()

        userNotificationCenter.removeAllPendingNotificationRequests()

        if settings.dailyBrief {
            scheduleDailyBriefNotification()
        }
    }

    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "task_reminder", "task_assignment":
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                navigateToTask(taskId)
            }

        case "new_message", "mention":
            if let conversationIdString = userInfo["conversationId"] as? String,
               let conversationId = UUID(uuidString: conversationIdString) {
                navigateToConversation(conversationId)
            }

        case "daily_brief":
            navigateToHome()

        default:
            break
        }
    }

    private func checkAuthorizationStatus() {
        userNotificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func loadNotificationSettings() {
        if let data = UserDefaults.standard.data(forKey: "notification_settings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = settings
        }
    }

    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notification_settings")
        }
    }

    private func getCurrentUser() -> User? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    private func navigateToTask(_ taskId: UUID) {
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTask"),
            object: nil,
            userInfo: ["taskId": taskId]
        )
    }

    private func navigateToConversation(_ conversationId: UUID) {
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToConversation"),
            object: nil,
            userInfo: ["conversationId": conversationId]
        )
    }

    private func navigateToHome() {
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToHome"),
            object: nil
        )
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationTap(response.notification.request.content.userInfo)
        completionHandler()
    }
}

struct NotificationSettings: Codable {
    var taskReminders = true
    var messageNotifications = true
    var mentionNotifications = true
    var taskAssignments = true
    var dailyBrief = true
    var briefTime: Date? = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))
    var quietHoursEnabled = false
    var quietHoursStart: Date?
    var quietHoursEnd: Date?

    var perConversationSettings: [String: ConversationNotificationSettings] = [:]
}

struct ConversationNotificationSettings: Codable {
    var notificationLevel: NotificationLevel = .all
    var isMuted = false
}

enum NotificationLevel: String, Codable, CaseIterable {
    case all = "all"
    case mentions = "mentions"
    case muted = "muted"
}