import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {

}

extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: UUID
    @NSManaged public var email: String
    @NSManaged public var displayName: String
    @NSManaged public var profileImageURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isActive: Bool

    @NSManaged public var ownedProjects: NSSet?
    @NSManaged public var projectMemberships: NSSet?
    @NSManaged public var ownedTasks: NSSet?
    @NSManaged public var assignedTasks: NSSet?
    @NSManaged public var followedTasks: NSSet?
    @NSManaged public var sentMessages: NSSet?
    @NSManaged public var conversationMemberships: NSSet?
}

extension User {
    @objc(addOwnedProjectsObject:)
    @NSManaged public func addToOwnedProjects(_ value: Project)

    @objc(removeOwnedProjectsObject:)
    @NSManaged public func removeFromOwnedProjects(_ value: Project)

    @objc(addOwnedProjects:)
    @NSManaged public func addToOwnedProjects(_ values: NSSet)

    @objc(removeOwnedProjects:)
    @NSManaged public func removeFromOwnedProjects(_ values: NSSet)
}