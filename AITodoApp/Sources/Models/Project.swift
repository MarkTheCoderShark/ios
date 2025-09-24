import Foundation
import CoreData

public enum ProjectVisibility: String, CaseIterable {
    case `private` = "private"
    case shared = "shared"
}

public enum ProjectRole: String, CaseIterable {
    case owner = "owner"
    case editor = "editor"
    case commenter = "commenter"
}

@objc(Project)
public class Project: NSManagedObject {

}

extension Project {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var projectDescription: String?
    @NSManaged public var visibilityRaw: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isArchived: Bool

    @NSManaged public var owner: User
    @NSManaged public var tasks: NSSet?
    @NSManaged public var memberships: NSSet?

    public var visibility: ProjectVisibility {
        get { ProjectVisibility(rawValue: visibilityRaw) ?? .`private` }
        set { visibilityRaw = newValue.rawValue }
    }
}

extension Project {
    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}

@objc(ProjectMembership)
public class ProjectMembership: NSManagedObject {

}

extension ProjectMembership {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectMembership> {
        return NSFetchRequest<ProjectMembership>(entityName: "ProjectMembership")
    }

    @NSManaged public var roleRaw: String
    @NSManaged public var joinedAt: Date
    @NSManaged public var isActive: Bool

    @NSManaged public var project: Project
    @NSManaged public var user: User

    public var role: ProjectRole {
        get { ProjectRole(rawValue: roleRaw) ?? .commenter }
        set { roleRaw = newValue.rawValue }
    }
}