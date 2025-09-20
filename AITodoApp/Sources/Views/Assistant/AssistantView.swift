import SwiftUI

struct AssistantView: View {
    @State private var messages: [AssistantMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    AssistantWelcomeView()
                } else {
                    MessageListView(messages: messages)
                }

                AssistantInputBar(
                    inputText: $inputText,
                    isLoading: isLoading,
                    onSend: sendMessage
                )
            }
            .navigationTitle("Assistant")
        }
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = AssistantMessage(
            id: UUID(),
            content: inputText,
            isUser: true,
            timestamp: Date()
        )

        messages.append(userMessage)
        let messageText = inputText
        inputText = ""
        isLoading = true

        Task {
            await simulateAIResponse(for: messageText)
        }
    }

    private func simulateAIResponse(for userMessage: String) async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let response = generateResponse(for: userMessage)
        let aiMessage = AssistantMessage(
            id: UUID(),
            content: response,
            isUser: false,
            timestamp: Date()
        )

        await MainActor.run {
            messages.append(aiMessage)
            isLoading = false
        }
    }

    private func generateResponse(for message: String) -> String {
        let lowercased = message.lowercased()

        if lowercased.contains("task") || lowercased.contains("todo") {
            return "I can help you manage your tasks! You can create new tasks, set priorities, add due dates, and organize them into projects. Would you like me to help you create a task or analyze your current workload?"
        } else if lowercased.contains("email") || lowercased.contains("gmail") {
            return "I can help you with email management! Once you connect your Gmail account, I can summarize emails, extract action items, and even convert emails into tasks. Would you like me to help you set up Gmail integration?"
        } else if lowercased.contains("schedule") || lowercased.contains("calendar") {
            return "I can help you with scheduling and time management. I can analyze your tasks, suggest optimal work times, and help you plan your day. What would you like to schedule?"
        } else if lowercased.contains("team") || lowercased.contains("collaborate") {
            return "I can help you with team collaboration! You can share tasks, create group conversations, assign work to team members, and track project progress. Would you like to start a shared project?"
        } else {
            return "I'm your AI assistant for productivity and task management. I can help you:\n\n• Create and organize tasks\n• Summarize emails and extract action items\n• Plan your schedule and set priorities\n• Collaborate with team members\n• Analyze your productivity patterns\n\nWhat would you like help with today?"
        }
    }
}

struct AssistantMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct AssistantWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("AI Assistant")
                    .font(.title)
                    .fontWeight(.bold)

                Text("I'm here to help you stay productive and organized. Ask me anything about your tasks, emails, or schedule.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("Try asking:")
                    .font(.headline)
                    .fontWeight(.semibold)

                PromptChipGrid()
            }

            Spacer()
        }
        .padding()
    }
}

struct PromptChipGrid: View {
    let prompts = [
        "What tasks are due today?",
        "Summarize my recent emails",
        "Create a task for project review",
        "Show my productivity insights",
        "Help me plan my week",
        "Find mentions in conversations"
    ]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(prompts, id: \.self) { prompt in
                PromptChip(text: prompt)
            }
        }
    }
}

struct PromptChip: View {
    let text: String

    var body: some View {
        Button(action: {}) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(16)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

struct MessageListView: View {
    let messages: [AssistantMessage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: AssistantMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .cornerRadius(4, corners: .bottomTrailing)

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(.top, 2)

                        Text(message.content)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(18)
                            .cornerRadius(4, corners: .bottomLeading)
                    }

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }

                Spacer(minLength: 60)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AssistantInputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Ask me anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .disabled(isLoading)

                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .frame(width: 36, height: 36)
                .background(canSend ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(18)
                .disabled(!canSend || isLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AssistantView()
}