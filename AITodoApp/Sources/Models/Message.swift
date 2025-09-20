import Foundation
import CoreData

public enum MessageType: String, CaseIterable {
    case text = "text"
    case system = "system"
    case taskUpdate = "task_update"
}

@objc(Message)
public class Message: NSManagedObject {

}

extension Message {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var typeRaw: String
    @NSManaged public var createdAt: Date
    @NSManaged public var editedAt: Date?
    @NSManaged public var isDeleted: Bool
    @NSManaged public var metadata: Data?

    @NSManaged public var sender: User
    @NSManaged public var conversation: Conversation
    @NSManaged public var attachments: NSSet?
    @NSManaged public var linkedTasks: NSSet?
    @NSManaged public var deliveryReceipts: NSSet?
    @NSManaged public var readReceipts: NSSet?

    public var type: MessageType {
        get { MessageType(rawValue: typeRaw) ?? .text }
        set { typeRaw = newValue.rawValue }
    }
}

extension Message {
    @objc(addLinkedTasksObject:)
    @NSManaged public func addToLinkedTasks(_ value: Task)

    @objc(removeLinkedTasksObject:)
    @NSManaged public func removeFromLinkedTasks(_ value: Task)

    @objc(addLinkedTasks:)
    @NSManaged public func addToLinkedTasks(_ values: NSSet)

    @objc(removeLinkedTasks:)
    @NSManaged public func removeFromLinkedTasks(_ values: NSSet)
}

@objc(MessageAttachment)
public class MessageAttachment: NSManagedObject {

}

extension MessageAttachment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageAttachment> {
        return NSFetchRequest<MessageAttachment>(entityName: "MessageAttachment")
    }

    @NSManaged public var id: UUID
    @NSManaged public var filename: String
    @NSManaged public var fileURL: String
    @NSManaged public var mimeType: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var createdAt: Date

    @NSManaged public var message: Message
}

@objc(DeliveryReceipt)
public class DeliveryReceipt: NSManagedObject {

}

extension DeliveryReceipt {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeliveryReceipt> {
        return NSFetchRequest<DeliveryReceipt>(entityName: "DeliveryReceipt")
    }

    @NSManaged public var deliveredAt: Date

    @NSManaged public var message: Message
    @NSManaged public var user: User
}

@objc(ReadReceipt)
public class ReadReceipt: NSManagedObject {

}

extension ReadReceipt {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadReceipt> {
        return NSFetchRequest<ReadReceipt>(entityName: "ReadReceipt")
    }

    @NSManaged public var readAt: Date

    @NSManaged public var message: Message
    @NSManaged public var user: User
}