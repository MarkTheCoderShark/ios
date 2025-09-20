import Foundation
import SwiftUI

struct Constants {
    struct API {
        static let baseURL = "https://api.aitodoapp.com/v1"
        static let websocketURL = "wss://api.aitodoapp.com/socket"
        static let timeout: TimeInterval = 30.0
    }

    struct UserDefaults {
        static let authToken = "auth_token"
        static let userId = "user_id"
        static let gmailAccessToken = "gmail_access_token"
        static let notificationSettings = "notification_settings"
        static let appPreferences = "app_preferences"
        static let onboardingCompleted = "onboarding_completed"
    }

    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 2
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24

        static let tabBarHeight: CGFloat = 83
        static let navigationBarHeight: CGFloat = 44

        struct Animation {
            static let standard = Animation.easeInOut(duration: 0.3)
            static let quick = Animation.easeInOut(duration: 0.15)
            static let slow = Animation.easeInOut(duration: 0.5)
        }
    }

    struct Limits {
        static let maxTaskTitleLength = 200
        static let maxTaskNotesLength = 2000
        static let maxMessageLength = 1000
        static let maxConversationNameLength = 100
        static let maxProjectNameLength = 100
        static let maxProjectDescriptionLength = 500

        static let maxFileSize = 50 * 1024 * 1024 // 50MB
        static let maxFilesPerMessage = 10

        static let tasksPerPage = 50
        static let messagesPerPage = 50
        static let emailsPerPage = 25
    }

    struct Features {
        static let isMessagingEnabled = true
        static let isGmailIntegrationEnabled = true
        static let isAIFeaturesEnabled = true
        static let isPushNotificationsEnabled = true
        static let isVoiceMessagesEnabled = false
        static let isFileAttachmentsEnabled = true
    }

    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red

        static let taskLowPriority = Color.blue
        static let taskMediumPriority = Color.orange
        static let taskHighPriority = Color.red
        static let taskUrgentPriority = Color.purple

        static let statusPending = Color.gray
        static let statusInProgress = Color.blue
        static let statusCompleted = Color.green
        static let statusCancelled = Color.red
    }

    struct Fonts {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let footnote = Font.footnote
    }

    struct Icons {
        static let home = "house.fill"
        static let tasks = "checkmark.circle.fill"
        static let communications = "message.fill"
        static let assistant = "brain.head.profile"
        static let settings = "gearshape.fill"

        static let taskPending = "circle"
        static let taskCompleted = "checkmark.circle.fill"
        static let taskInProgress = "clock.circle"
        static let taskCancelled = "xmark.circle"

        static let priorityLow = "arrow.down.circle"
        static let priorityMedium = "minus.circle"
        static let priorityHigh = "arrow.up.circle"
        static let priorityUrgent = "exclamationmark.triangle.fill"

        static let email = "envelope.fill"
        static let message = "message.fill"
        static let mention = "at.badge.plus"
        static let attachment = "paperclip"
        static let camera = "camera.fill"
        static let microphone = "mic.fill"

        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let share = "square.and.arrow.up"
        static let filter = "line.3.horizontal.decrease.circle"
        static let search = "magnifyingglass"
        static let refresh = "arrow.clockwise"
    }

    struct Notifications {
        struct Types {
            static let taskReminder = "task_reminder"
            static let taskAssignment = "task_assignment"
            static let taskStatusChanged = "task_status_changed"
            static let newMessage = "new_message"
            static let mention = "mention"
            static let dailyBrief = "daily_brief"
            static let emailSummary = "email_summary"
        }

        struct Categories {
            static let tasks = "TASKS"
            static let messages = "MESSAGES"
            static let general = "GENERAL"
        }
    }

    struct AI {
        static let maxPromptLength = 4000
        static let maxResponseLength = 1000
        static let defaultModel = "gpt-3.5-turbo"
        static let temperature: Double = 0.7
        static let maxTokens = 500

        struct Prompts {
            static let dailyBriefSystem = "You are an AI assistant that creates concise daily briefs for productivity. Focus on priorities and actionable insights."
            static let emailSummarySystem = "You are an AI assistant that summarizes emails. Focus on key information and action items."
            static let taskExtractionSystem = "You are an AI assistant that extracts actionable tasks from conversations. Be specific and clear."
            static let threadSummarySystem = "You are an AI assistant that summarizes conversation threads. Focus on decisions and action items."
        }
    }

    struct Performance {
        static let imageCompressionQuality: CGFloat = 0.8
        static let thumbnailSize = CGSize(width: 200, height: 200)
        static let previewImageSize = CGSize(width: 600, height: 400)

        static let cacheExpiryDays = 7
        static let maxCacheSize = 100 * 1024 * 1024 // 100MB

        static let backgroundTaskTimeout: TimeInterval = 30.0
        static let networkTimeout: TimeInterval = 30.0
        static let socketReconnectDelay: TimeInterval = 2.0
    }
}