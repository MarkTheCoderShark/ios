import Foundation
import CoreData
import SocketIO
import Combine

class MessagingService: ObservableObject {
    @Published var isConnected = false
    @Published var conversations: [Conversation] = []
    @Published var activeConversation: Conversation?
    @Published var messages: [Message] = []

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSocketConnection()
        loadConversations()
    }

    private func setupSocketConnection() {
        guard let url = URL(string: SecureConfiguration.shared.websocketURL) else { return }

        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .reconnectAttempts(3),
            .reconnectWait(2)
        ])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = true
                print("Socket connected")
            }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = false
                print("Socket disconnected")
            }
        }

        socket?.on("message") { [weak self] data, _ in
            self?.handleIncomingMessage(data: data)
        }

        socket?.on("message_delivered") { [weak self] data, _ in
            self?.handleMessageDelivery(data: data)
        }

        socket?.on("message_read") { [weak self] data, _ in
            self?.handleMessageRead(data: data)
        }

        socket?.on("conversation_updated") { [weak self] data, _ in
            self?.handleConversationUpdate(data: data)
        }

        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        isConnected = false
    }

    func joinConversation(_ conversation: Conversation) {
        activeConversation = conversation
        socket?.emit("join_conversation", conversation.id.uuidString)
        loadMessages(for: conversation)
        markConversationAsRead(conversation)
    }

    func leaveConversation() {
        if let conversation = activeConversation {
            socket?.emit("leave_conversation", conversation.id.uuidString)
        }
        activeConversation = nil
        messages = []
    }

    func sendMessage(text: String, to conversation: Conversation) {
        guard let currentUser = getCurrentUser() else { return }

        let messageId = UUID()
        let messageData: [String: Any] = [
            "id": messageId.uuidString,
            "conversationId": conversation.id.uuidString,
            "senderId": currentUser.id.uuidString,
            "text": text,
            "type": MessageType.text.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        socket?.emit("send_message", messageData)

        let context = persistenceController.backgroundContext()
        context.perform {
            let message = Message(context: context)
            message.id = messageId
            message.text = text
            message.type = .text
            message.createdAt = Date()
            message.sender = currentUser
            message.conversation = conversation

            conversation.lastActivityAt = Date()
            conversation.updatedAt = Date()

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.loadMessages(for: conversation)
                }
            } catch {
                print("Failed to save message: \(error)")
            }
        }
    }

    func sendTaskToConversation(_ task: Task, to conversation: Conversation) {
        guard let currentUser = getCurrentUser() else { return }

        let messageId = UUID()
        let messageData: [String: Any] = [
            "id": messageId.uuidString,
            "conversationId": conversation.id.uuidString,
            "senderId": currentUser.id.uuidString,
            "text": "shared a task: \(task.title)",
            "type": MessageType.system.rawValue,
            "taskId": task.id.uuidString,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        socket?.emit("send_message", messageData)

        let context = persistenceController.backgroundContext()
        context.perform {
            let message = Message(context: context)
            message.id = messageId
            message.text = "shared a task: \(task.title)"
            message.type = .system
            message.createdAt = Date()
            message.sender = currentUser
            message.conversation = conversation
            message.addToLinkedTasks(task)

            let taskLink = TaskConversationLink(context: context)
            taskLink.task = task
            taskLink.conversation = conversation
            taskLink.createdBy = currentUser
            taskLink.createdAt = Date()

            conversation.lastActivityAt = Date()
            conversation.updatedAt = Date()

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.loadMessages(for: conversation)
                }
            } catch {
                print("Failed to save task message: \(error)")
            }
        }
    }

    func createConversation(with participants: [User], name: String? = nil, type: ConversationType = .group) {
        guard let currentUser = getCurrentUser() else { return }

        let conversationId = UUID()
        let conversationData: [String: Any] = [
            "id": conversationId.uuidString,
            "type": type.rawValue,
            "name": name as Any,
            "ownerId": currentUser.id.uuidString,
            "participantIds": participants.map { $0.id.uuidString }
        ]

        socket?.emit("create_conversation", conversationData)

        let context = persistenceController.backgroundContext()
        context.perform {
            let conversation = Conversation(context: context)
            conversation.id = conversationId
            conversation.type = type
            conversation.name = name
            conversation.owner = currentUser
            conversation.createdAt = Date()
            conversation.updatedAt = Date()
            conversation.lastActivityAt = Date()
            conversation.isArchived = false

            let ownerMembership = ConversationMembership(context: context)
            ownerMembership.conversation = conversation
            ownerMembership.user = currentUser
            ownerMembership.role = .owner
            ownerMembership.notificationLevel = .all
            ownerMembership.joinedAt = Date()
            ownerMembership.isActive = true

            for participant in participants {
                let membership = ConversationMembership(context: context)
                membership.conversation = conversation
                membership.user = participant
                membership.role = .commenter
                membership.notificationLevel = .all
                membership.joinedAt = Date()
                membership.isActive = true
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.loadConversations()
                }
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }

    private func handleIncomingMessage(data: [Any]) {
        guard let messageDict = data.first as? [String: Any],
              let messageId = messageDict["id"] as? String,
              let conversationId = messageDict["conversationId"] as? String,
              let senderId = messageDict["senderId"] as? String,
              let text = messageDict["text"] as? String,
              let typeString = messageDict["type"] as? String,
              let timestampString = messageDict["timestamp"] as? String else {
            return
        }

        let context = persistenceController.backgroundContext()
        context.perform {
            guard let conversation = self.findConversation(by: conversationId, in: context),
                  let sender = self.findUser(by: senderId, in: context),
                  let messageUUID = UUID(uuidString: messageId),
                  let type = MessageType(rawValue: typeString) else {
                return
            }

            let existingMessage = self.findMessage(by: messageUUID, in: context)
            if existingMessage != nil {
                return
            }

            let message = Message(context: context)
            message.id = messageUUID
            message.text = text
            message.type = type
            message.sender = sender
            message.conversation = conversation

            let formatter = ISO8601DateFormatter()
            message.createdAt = formatter.date(from: timestampString) ?? Date()

            conversation.lastActivityAt = message.createdAt
            conversation.updatedAt = Date()

            if let taskId = messageDict["taskId"] as? String,
               let taskUUID = UUID(uuidString: taskId),
               let task = self.findTask(by: taskUUID, in: context) {
                message.addToLinkedTasks(task)
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    if let activeConv = self.activeConversation,
                       activeConv.id == conversation.id {
                        self.loadMessages(for: activeConv)
                    }
                    self.loadConversations()
                }
            } catch {
                print("Failed to save incoming message: \(error)")
            }
        }
    }

    private func handleMessageDelivery(data: [Any]) {
        guard let deliveryDict = data.first as? [String: Any],
              let messageId = deliveryDict["messageId"] as? String,
              let userId = deliveryDict["userId"] as? String else {
            return
        }

        let context = persistenceController.backgroundContext()
        context.perform {
            guard let messageUUID = UUID(uuidString: messageId),
                  let userUUID = UUID(uuidString: userId),
                  let message = self.findMessage(by: messageUUID, in: context),
                  let user = self.findUser(by: userUUID, in: context) else {
                return
            }

            let existingReceipt = message.deliveryReceipts?.allObjects.first { receipt in
                (receipt as? DeliveryReceipt)?.user.id == user.id
            }

            if existingReceipt == nil {
                let receipt = DeliveryReceipt(context: context)
                receipt.message = message
                receipt.user = user
                receipt.deliveredAt = Date()

                do {
                    try context.save()
                } catch {
                    print("Failed to save delivery receipt: \(error)")
                }
            }
        }
    }

    private func handleMessageRead(data: [Any]) {
        guard let readDict = data.first as? [String: Any],
              let messageId = readDict["messageId"] as? String,
              let userId = readDict["userId"] as? String else {
            return
        }

        let context = persistenceController.backgroundContext()
        context.perform {
            guard let messageUUID = UUID(uuidString: messageId),
                  let userUUID = UUID(uuidString: userId),
                  let message = self.findMessage(by: messageUUID, in: context),
                  let user = self.findUser(by: userUUID, in: context) else {
                return
            }

            let existingReceipt = message.readReceipts?.allObjects.first { receipt in
                (receipt as? ReadReceipt)?.user.id == user.id
            }

            if existingReceipt == nil {
                let receipt = ReadReceipt(context: context)
                receipt.message = message
                receipt.user = user
                receipt.readAt = Date()

                do {
                    try context.save()
                } catch {
                    print("Failed to save read receipt: \(error)")
                }
            }
        }
    }

    private func handleConversationUpdate(data: [Any]) {
        DispatchQueue.main.async {
            self.loadConversations()
        }
    }

    private func loadConversations() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.lastActivityAt, ascending: false)]
        request.predicate = NSPredicate(format: "isArchived == NO")

        do {
            conversations = try context.fetch(request)
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }

    private func loadMessages(for conversation: Conversation) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Message.createdAt, ascending: true)]
        request.predicate = NSPredicate(format: "conversation == %@ AND isDeleted == NO", conversation)

        do {
            messages = try context.fetch(request)
        } catch {
            print("Failed to load messages: \(error)")
        }
    }

    private func markConversationAsRead(_ conversation: Conversation) {
        guard let currentUser = getCurrentUser() else { return }

        let context = persistenceController.backgroundContext()
        context.perform {
            let membershipRequest: NSFetchRequest<ConversationMembership> = ConversationMembership.fetchRequest()
            membershipRequest.predicate = NSPredicate(format: "conversation == %@ AND user == %@", conversation, currentUser)

            do {
                let memberships = try context.fetch(membershipRequest)
                if let membership = memberships.first {
                    membership.lastReadAt = Date()
                    try context.save()
                }
            } catch {
                print("Failed to update read status: \(error)")
            }
        }
    }

    private func getCurrentUser() -> User? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }

    private func findConversation(by id: String, in context: NSManagedObjectContext) -> Conversation? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    private func findUser(by id: String, in context: NSManagedObjectContext) -> User? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    private func findMessage(by id: UUID, in context: NSManagedObjectContext) -> Message? {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    private func findTask(by id: UUID, in context: NSManagedObjectContext) -> Task? {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}