import Foundation
import SwiftUI

extension Date {
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }

    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    func isThisWeek() -> Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func dueDateDisplay() -> String {
        if isToday() {
            return "Today"
        } else if isTomorrow() {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
}

extension String {
    func extractMentions() -> [String] {
        let pattern = #"@(\w+)"#

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: utf16.count)
            let matches = regex.matches(in: self, options: [], range: range)

            return matches.compactMap { match in
                Range(match.range(at: 1), in: self).map { String(self[$0]) }
            }
        } catch {
            return []
        }
    }

    func highlightMentions() -> AttributedString {
        var attributedString = AttributedString(self)

        let mentions = extractMentions()
        for mention in mentions {
            let mentionText = "@\(mention)"
            if let range = attributedString.range(of: mentionText) {
                attributedString[range].foregroundColor = .blue
                attributedString[range].font = .body.weight(.medium)
            }
        }

        return attributedString
    }

    func truncated(to length: Int) -> String {
        if count <= length {
            return self
        }

        return String(prefix(length)) + "..."
    }
}

extension Color {
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let secondaryGray = Color(red: 0.56, green: 0.56, blue: 0.58)
    static let backgroundGray = Color(red: 0.95, green: 0.95, blue: 0.97)

    static func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .urgent:
            return .purple
        }
    }

    static func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
    static let taskUpdated = Notification.Name("taskUpdated")
    static let taskDeleted = Notification.Name("taskDeleted")
    static let messageReceived = Notification.Name("messageReceived")
    static let conversationUpdated = Notification.Name("conversationUpdated")
}