import Foundation
import CoreData

public enum ConversationType: String, CaseIterable {
    case dm = "dm"
    case group = "group"
}

public enum ConversationRole: String, CaseIterable {
    case owner = "owner"
    case editor = "editor"
    case commenter = "commenter"
}

public enum NotificationLevel: String, CaseIterable, Codable {
    case all = "all"
    case mentions = "mentions"
    case muted = "muted"
}

@objc(Conversation)
public class Conversation: NSManagedObject {

}

extension Conversation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }

    @NSManaged public var id: UUID
    @NSManaged public var typeRaw: String
    @NSManaged public var name: String?
    @NSManaged public var avatarURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastActivityAt: Date?
    @NSManaged public var isArchived: Bool

    @NSManaged public var owner: User?
    @NSManaged public var messages: NSSet?
    @NSManaged public var memberships: NSSet?
    @NSManaged public var taskLinks: NSSet?

    public var type: ConversationType {
        get { ConversationType(rawValue: typeRaw) ?? .dm }
        set { typeRaw = newValue.rawValue }
    }
}

extension Conversation {
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

@objc(ConversationMembership)
public class ConversationMembership: NSManagedObject {

}

extension ConversationMembership {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationMembership> {
        return NSFetchRequest<ConversationMembership>(entityName: "ConversationMembership")
    }

    @NSManaged public var roleRaw: String
    @NSManaged public var notificationLevelRaw: String
    @NSManaged public var joinedAt: Date
    @NSManaged public var isActive: Bool
    @NSManaged public var lastReadAt: Date?

    @NSManaged public var conversation: Conversation
    @NSManaged public var user: User

    public var role: ConversationRole {
        get { ConversationRole(rawValue: roleRaw) ?? .commenter }
        set { roleRaw = newValue.rawValue }
    }

    public var notificationLevel: NotificationLevel {
        get { NotificationLevel(rawValue: notificationLevelRaw) ?? .all }
        set { notificationLevelRaw = newValue.rawValue }
    }
}
