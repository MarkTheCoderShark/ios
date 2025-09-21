import Foundation
import Combine

// MARK: - Service Protocol Definitions

protocol AIServiceProtocol: ObservableObject {
    var isProcessing: Bool { get }

    func generateDailyBrief() async -> DailyBrief?
    func summarizeThread(_ conversation: Conversation) async -> ThreadSummary?
    func extractActionsFromThread(_ conversation: Conversation) async -> [ActionItem]
    func summarizeEmail(_ email: GmailEmail) async -> EmailSummary?
    func suggestTaskPriorities(_ tasks: [Task]) async -> [TaskPrioritySuggestion]
    func generateTaskFromText(_ text: String) async -> TaskSuggestion?
}

protocol AuthenticationServiceProtocol: ObservableObject {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var isLoading: Bool { get }

    func signInWithApple() async
    func signInWithGoogle() async
    func signOut()
    func checkAuthenticationState()
}

protocol GmailServiceProtocol: ObservableObject {
    var isConnected: Bool { get }
    var emails: [GmailEmail] { get }
    var isLoading: Bool { get }

    func connectGmail() async
    func disconnectGmail()
    func fetchEmails() async
    func markAsRead(_ email: GmailEmail) async
    func createTaskFromEmail(_ email: GmailEmail) -> Task?
}

protocol KeychainManagerProtocol {
    func save(_ data: Data, service: String, account: String) throws
    func read(service: String, account: String) throws -> Data
    func delete(service: String, account: String) throws
    func saveString(_ string: String, service: String, account: String) throws
    func readString(service: String, account: String) throws -> String
}

protocol ConfigurationServiceProtocol {
    func getValue(for key: ConfigurationKey) -> String?
    var openAIAPIKey: String? { get }
    var googleClientID: String? { get }
    var websocketURL: String { get }
}

// MARK: - Data Model Protocols

protocol Identifiable {
    var id: UUID { get }
}

protocol Timestampable {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

protocol Ownable {
    var owner: User { get }
}

// MARK: - View Model Protocol

protocol TasksViewModelProtocol: ObservableObject {
    var tasks: [Task] { get }
    var searchText: String { get set }
    var selectedFilter: TasksViewModel.TaskFilter { get set }
    var isLoading: Bool { get }
    var error: AppError? { get }

    func fetchTasks()
    func createTask(title: String, description: String, priority: String, dueDate: Date) async
    func updateTask(_ task: Task) async
    func deleteTask(_ task: Task) async
}