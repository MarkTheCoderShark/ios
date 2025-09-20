import Foundation
import CoreData

public enum TaskStatus: String, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

public enum TaskPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}

@objc(Task)
public class Task: NSManagedObject {

}

extension Task {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var statusRaw: String
    @NSManaged public var priorityRaw: String
    @NSManaged public var dueDate: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isShared: Bool
    @NSManaged public var estimatedDuration: Int32

    @NSManaged public var owner: User
    @NSManaged public var project: Project?
    @NSManaged public var assignees: NSSet?
    @NSManaged public var followers: NSSet?
    @NSManaged public var linkedMessages: NSSet?
    @NSManaged public var conversationLinks: NSSet?

    public var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    public var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
}

extension Task {
    @objc(addAssigneesObject:)
    @NSManaged public func addToAssignees(_ value: User)

    @objc(removeAssigneesObject:)
    @NSManaged public func removeFromAssignees(_ value: User)

    @objc(addAssignees:)
    @NSManaged public func addToAssignees(_ values: NSSet)

    @objc(removeAssignees:)
    @NSManaged public func removeFromAssignees(_ values: NSSet)

    @objc(addFollowersObject:)
    @NSManaged public func addToFollowers(_ value: User)

    @objc(removeFollowersObject:)
    @NSManaged public func removeFromFollowers(_ value: User)

    @objc(addFollowers:)
    @NSManaged public func addToFollowers(_ values: NSSet)

    @objc(removeFollowers:)
    @NSManaged public func removeFromFollowers(_ values: NSSet)
}