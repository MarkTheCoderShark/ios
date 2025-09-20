import Foundation
import Combine

class AIService: ObservableObject {
    @Published var isProcessing = false
    @Published var dailyBrief: DailyBrief?
    @Published var taskSuggestions: [TaskSuggestion] = []

    private let baseURL = "https://api.openai.com/v1"
    private let apiKey = "your-openai-api-key"
    private var cancellables = Set<AnyCancellable>()

    func generateDailyBrief() async -> DailyBrief? {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let tasks = await fetchUserTasks()
            let emails = await fetchRecentEmails()
            let messages = await fetchRecentMessages()

            let prompt = createDailyBriefPrompt(tasks: tasks, emails: emails, messages: messages)
            let response = await callOpenAI(prompt: prompt, maxTokens: 300)

            let brief = parseDailyBriefResponse(response)

            await MainActor.run {
                self.dailyBrief = brief
                self.isProcessing = false
            }

            return brief

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to generate daily brief: \(error)")
            return nil
        }
    }

    func summarizeThread(_ conversation: Conversation) async -> ThreadSummary? {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let messages = await fetchConversationMessages(conversation)
            let prompt = createThreadSummaryPrompt(messages: messages)
            let response = await callOpenAI(prompt: prompt, maxTokens: 200)

            let summary = parseThreadSummaryResponse(response)

            await MainActor.run {
                self.isProcessing = false
            }

            return summary

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to summarize thread: \(error)")
            return nil
        }
    }

    func extractActionsFromThread(_ conversation: Conversation) async -> [ActionItem] {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let messages = await fetchConversationMessages(conversation)
            let prompt = createActionExtractionPrompt(messages: messages)
            let response = await callOpenAI(prompt: prompt, maxTokens: 250)

            let actions = parseActionItemsResponse(response)

            await MainActor.run {
                self.isProcessing = false
            }

            return actions

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to extract actions: \(error)")
            return []
        }
    }

    func summarizeEmail(_ email: GmailEmail) async -> EmailSummary? {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let prompt = createEmailSummaryPrompt(email: email)
            let response = await callOpenAI(prompt: prompt, maxTokens: 150)

            let summary = parseEmailSummaryResponse(response)

            await MainActor.run {
                self.isProcessing = false
            }

            return summary

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to summarize email: \(error)")
            return nil
        }
    }

    func suggestTaskPriorities(_ tasks: [Task]) async -> [TaskPrioritySuggestion] {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let prompt = createPrioritySuggestionPrompt(tasks: tasks)
            let response = await callOpenAI(prompt: prompt, maxTokens: 200)

            let suggestions = parsePrioritySuggestionsResponse(response)

            await MainActor.run {
                self.isProcessing = false
            }

            return suggestions

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to suggest priorities: \(error)")
            return []
        }
    }

    func generateTaskFromText(_ text: String) async -> TaskSuggestion? {
        await MainActor.run {
            isProcessing = true
        }

        do {
            let prompt = createTaskGenerationPrompt(text: text)
            let response = await callOpenAI(prompt: prompt, maxTokens: 100)

            let suggestion = parseTaskSuggestionResponse(response)

            await MainActor.run {
                self.isProcessing = false
            }

            return suggestion

        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            print("Failed to generate task: \(error)")
            return nil
        }
    }

    private func callOpenAI(prompt: String, maxTokens: Int) async -> String? {
        guard let url = URL(string: "\(baseURL)/chat/completions") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.7
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)

            if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = response["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }

        } catch {
            print("OpenAI API error: \(error)")
        }

        return nil
    }

    private func createDailyBriefPrompt(tasks: [Task], emails: [GmailEmail], messages: [Message]) -> String {
        let taskCount = tasks.count
        let dueTodayCount = tasks.filter { Calendar.current.isDateInToday($0.dueDate ?? Date.distantPast) }.count
        let emailCount = emails.count
        let messageCount = messages.count

        return """
        Create a brief daily summary based on the following data:
        - \(taskCount) total tasks, \(dueTodayCount) due today
        - \(emailCount) new emails
        - \(messageCount) new messages

        Provide a motivational and actionable summary in 2-3 sentences that helps the user prioritize their day.
        Focus on what's most important and time-sensitive.
        """
    }

    private func createThreadSummaryPrompt(messages: [Message]) -> String {
        let messageTexts = messages.map { "[\($0.sender.displayName)]: \($0.text)" }.joined(separator: "\n")

        return """
        Summarize this conversation thread in 3-5 bullet points:

        \(messageTexts)

        Focus on:
        - Key decisions made
        - Action items discussed
        - Important information shared
        - Any blockers or concerns raised
        """
    }

    private func createActionExtractionPrompt(messages: [Message]) -> String {
        let messageTexts = messages.map { "[\($0.sender.displayName)]: \($0.text)" }.joined(separator: "\n")

        return """
        Extract action items from this conversation:

        \(messageTexts)

        Return a JSON array of action items with this format:
        [{"title": "Action description", "assignee": "Person name", "due_hint": "timeframe", "confidence": 0.8}]

        Only include clear, actionable items that someone needs to do.
        """
    }

    private func createEmailSummaryPrompt(email: GmailEmail) -> String {
        return """
        Summarize this email in 2-3 sentences:

        From: \(email.sender)
        Subject: \(email.subject)
        Content: \(email.body.prefix(500))

        Focus on:
        - Main purpose/request
        - Any action items for the recipient
        - Key information or deadlines
        """
    }

    private func createPrioritySuggestionPrompt(tasks: [Task]) -> String {
        let taskDescriptions = tasks.map { "\($0.title) - Due: \($0.dueDate?.formatted() ?? "No date")" }.joined(separator: "\n")

        return """
        Analyze these tasks and suggest priority levels (high/medium/low):

        \(taskDescriptions)

        Consider due dates, typical importance of task types, and urgency indicators.
        Return JSON format: [{"task": "task title", "suggested_priority": "high", "reason": "explanation"}]
        """
    }

    private func createTaskGenerationPrompt(text: String) -> String {
        return """
        Convert this text into a task suggestion:

        "\(text)"

        Return JSON format:
        {"title": "Clear task title", "notes": "Additional context", "priority": "medium", "estimated_duration": 30}

        Make the title actionable and specific.
        """
    }

    private func parseDailyBriefResponse(_ response: String?) -> DailyBrief? {
        guard let response = response else { return nil }

        return DailyBrief(
            summary: response,
            topPriorities: [],
            upcomingDeadlines: [],
            suggestions: []
        )
    }

    private func parseThreadSummaryResponse(_ response: String?) -> ThreadSummary? {
        guard let response = response else { return nil }

        let bullets = response.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ThreadSummary(
            summary: bullets,
            keyDecisions: [],
            actionItems: [],
            participants: []
        )
    }

    private func parseActionItemsResponse(_ response: String?) -> [ActionItem] {
        guard let response = response,
              let data = response.data(using: .utf8) else { return [] }

        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { dict in
                    guard let title = dict["title"] as? String else { return nil }

                    return ActionItem(
                        title: title,
                        assignee: dict["assignee"] as? String,
                        dueHint: dict["due_hint"] as? String,
                        confidence: dict["confidence"] as? Double ?? 0.5
                    )
                }
            }
        } catch {
            print("Failed to parse action items: \(error)")
        }

        return []
    }

    private func parseEmailSummaryResponse(_ response: String?) -> EmailSummary? {
        guard let response = response else { return nil }

        return EmailSummary(
            summary: response,
            actionRequired: response.lowercased().contains("action") || response.lowercased().contains("need"),
            keyPoints: [],
            sentiment: .neutral
        )
    }

    private func parsePrioritySuggestionsResponse(_ response: String?) -> [TaskPrioritySuggestion] {
        guard let response = response,
              let data = response.data(using: .utf8) else { return [] }

        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { dict in
                    guard let task = dict["task"] as? String,
                          let priorityString = dict["suggested_priority"] as? String else { return nil }

                    let priority = TaskPriority(rawValue: priorityString) ?? .medium

                    return TaskPrioritySuggestion(
                        taskTitle: task,
                        suggestedPriority: priority,
                        reason: dict["reason"] as? String ?? ""
                    )
                }
            }
        } catch {
            print("Failed to parse priority suggestions: \(error)")
        }

        return []
    }

    private func parseTaskSuggestionResponse(_ response: String?) -> TaskSuggestion? {
        guard let response = response,
              let data = response.data(using: .utf8) else { return nil }

        do {
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = dict["title"] as? String {

                return TaskSuggestion(
                    title: title,
                    notes: dict["notes"] as? String,
                    priority: TaskPriority(rawValue: dict["priority"] as? String ?? "medium") ?? .medium,
                    estimatedDuration: dict["estimated_duration"] as? Int ?? 30
                )
            }
        } catch {
            print("Failed to parse task suggestion: \(error)")
        }

        return nil
    }

    private func fetchUserTasks() async -> [Task] {
        return []
    }

    private func fetchRecentEmails() async -> [GmailEmail] {
        return []
    }

    private func fetchRecentMessages() async -> [Message] {
        return []
    }

    private func fetchConversationMessages(_ conversation: Conversation) async -> [Message] {
        return []
    }
}

struct DailyBrief {
    let summary: String
    let topPriorities: [String]
    let upcomingDeadlines: [String]
    let suggestions: [String]
}

struct ThreadSummary {
    let summary: [String]
    let keyDecisions: [String]
    let actionItems: [String]
    let participants: [String]
}

struct ActionItem {
    let title: String
    let assignee: String?
    let dueHint: String?
    let confidence: Double
}

struct EmailSummary {
    let summary: String
    let actionRequired: Bool
    let keyPoints: [String]
    let sentiment: EmailSentiment
}

enum EmailSentiment {
    case positive, neutral, negative, urgent
}

struct TaskSuggestion {
    let title: String
    let notes: String?
    let priority: TaskPriority
    let estimatedDuration: Int
}

struct TaskPrioritySuggestion {
    let taskTitle: String
    let suggestedPriority: TaskPriority
    let reason: String
}