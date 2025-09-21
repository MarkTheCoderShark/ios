import Foundation
import GoogleSignIn
import Combine

class GmailService: ObservableObject {
    @Published var isConnected = false
    @Published var emails: [GmailEmail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "https://gmail.googleapis.com/gmail/v1"
    private var accessToken: String?
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkConnectionStatus()
    }

    func connectGmail() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                await MainActor.run {
                    self.errorMessage = "Unable to present Google Sign In"
                    self.isLoading = false
                }
                return
            }

            guard let clientID = SecureConfiguration.shared.googleClientID else {
                await MainActor.run {
                    self.errorMessage = "Google Client ID not configured"
                    self.isLoading = false
                }
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            if let accessToken = result.user.accessToken.tokenString {
                self.accessToken = accessToken
                try? KeychainManager.shared.saveString(accessToken, service: KeychainManager.ServiceKeys.appService, account: KeychainManager.ServiceKeys.gmailAccessToken)

                await MainActor.run {
                    self.isConnected = true
                    self.isLoading = false
                }

                await fetchEmails()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to connect Gmail: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func disconnectGmail() {
        accessToken = nil
        try? KeychainManager.shared.delete(service: KeychainManager.ServiceKeys.appService, account: KeychainManager.ServiceKeys.gmailAccessToken)

        DispatchQueue.main.async {
            self.isConnected = false
            self.emails = []
        }

        GIDSignIn.sharedInstance.signOut()
    }

    func fetchEmails() async {
        guard let accessToken = accessToken else { return }

        await MainActor.run {
            isLoading = true
        }

        do {
            guard let url = URL(string: "\(baseURL)/users/me/messages?maxResults=50&q=is:unread") else {
                await MainActor.run {
                    self.errorMessage = "Invalid URL for Gmail API"
                    self.isLoading = false
                }
                return
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GmailMessagesResponse.self, from: data)

            var fetchedEmails: [GmailEmail] = []

            for message in response.messages ?? [] {
                if let email = await fetchEmailDetails(messageId: message.id) {
                    fetchedEmails.append(email)
                }
            }

            await MainActor.run {
                self.emails = fetchedEmails.sorted { $0.receivedAt > $1.receivedAt }
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch emails: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func markAsRead(_ email: GmailEmail) async {
        guard let accessToken = accessToken else { return }

        do {
            guard let url = URL(string: "\(baseURL)/users/me/messages/\(email.id)/modify") else {
                await MainActor.run {
                    self.errorMessage = "Invalid URL for Gmail API"
                }
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["removeLabelIds": ["UNREAD"]]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, _) = try await URLSession.shared.data(for: request)

            await MainActor.run {
                if let index = self.emails.firstIndex(where: { $0.id == email.id }) {
                    self.emails[index].isRead = true
                }
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to mark email as read: \(error.localizedDescription)"
            }
        }
    }

    func createTaskFromEmail(_ email: GmailEmail) -> Task? {
        let context = PersistenceController.shared.container.viewContext

        guard let currentUser = getCurrentUser() else { return nil }

        let task = Task(context: context)
        task.id = UUID()
        task.title = "Email: \(email.subject)"
        task.notes = "From: \(email.sender)\n\n\(email.preview)"
        task.status = .pending
        task.priority = email.isImportant ? .high : .medium
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isShared = false
        task.estimatedDuration = 30
        task.owner = currentUser

        do {
            try context.save()
            return task
        } catch {
            print("Failed to create task from email: \(error)")
            return nil
        }
    }

    private func checkConnectionStatus() {
        if let token = try? KeychainManager.shared.readString(service: KeychainManager.ServiceKeys.appService, account: KeychainManager.ServiceKeys.gmailAccessToken) {
            accessToken = token
            isConnected = true
        }
    }

    private func fetchEmailDetails(messageId: String) async -> GmailEmail? {
        guard let accessToken = accessToken else { return nil }

        do {
            guard let url = URL(string: "\(baseURL)/users/me/messages/\(messageId)") else {
                return nil
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let message = try JSONDecoder().decode(GmailMessage.self, from: data)

            return parseGmailMessage(message)

        } catch {
            print("Failed to fetch email details: \(error)")
            return nil
        }
    }

    private func parseGmailMessage(_ message: GmailMessage) -> GmailEmail {
        let headers = message.payload.headers

        let subject = headers.first { $0.name == "Subject" }?.value ?? "No Subject"
        let from = headers.first { $0.name == "From" }?.value ?? "Unknown Sender"
        let date = headers.first { $0.name == "Date" }?.value ?? ""

        let isUnread = message.labelIds.contains("UNREAD")
        let isImportant = message.labelIds.contains("IMPORTANT")

        let body = extractEmailBody(from: message.payload)
        let preview = String(body.prefix(200))

        let receivedAt = parseEmailDate(date) ?? Date()

        return GmailEmail(
            id: message.id,
            subject: subject,
            sender: from,
            preview: preview,
            body: body,
            receivedAt: receivedAt,
            isRead: !isUnread,
            isImportant: isImportant
        )
    }

    private func extractEmailBody(from payload: GmailPayload) -> String {
        if let body = payload.body?.data {
            return decodeBase64(body)
        }

        if let parts = payload.parts {
            for part in parts {
                if part.mimeType == "text/plain", let body = part.body?.data {
                    return decodeBase64(body)
                }
            }

            for part in parts {
                if part.mimeType == "text/html", let body = part.body?.data {
                    return decodeBase64(body)
                }
            }
        }

        return ""
    }

    private func decodeBase64(_ data: String) -> String {
        let base64String = data.replacingOccurrences(of: "-", with: "+")
                              .replacingOccurrences(of: "_", with: "/")

        guard let decodedData = Data(base64Encoded: base64String),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            return ""
        }

        return decodedString
    }

    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter.date(from: dateString)
    }

    private func getCurrentUser() -> User? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}

struct GmailEmail {
    let id: String
    let subject: String
    let sender: String
    let preview: String
    let body: String
    let receivedAt: Date
    var isRead: Bool
    let isImportant: Bool
}

struct GmailMessagesResponse: Codable {
    let messages: [GmailMessageRef]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?
}

struct GmailMessageRef: Codable {
    let id: String
    let threadId: String
}

struct GmailMessage: Codable {
    let id: String
    let threadId: String
    let labelIds: [String]
    let snippet: String
    let payload: GmailPayload
    let internalDate: String
}

struct GmailPayload: Codable {
    let partId: String?
    let mimeType: String
    let filename: String?
    let headers: [GmailHeader]
    let body: GmailBody?
    let parts: [GmailPayload]?
}

struct GmailHeader: Codable {
    let name: String
    let value: String
}

struct GmailBody: Codable {
    let attachmentId: String?
    let size: Int?
    let data: String?
}