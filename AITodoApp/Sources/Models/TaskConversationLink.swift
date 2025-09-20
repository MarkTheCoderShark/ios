import Foundation
import CoreData

@objc(TaskConversationLink)
public class TaskConversationLink: NSManagedObject {

}

extension TaskConversationLink {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskConversationLink> {
        return NSFetchRequest<TaskConversationLink>(entityName: "TaskConversationLink")
    }

    @NSManaged public var createdAt: Date

    @NSManaged public var task: Task
    @NSManaged public var conversation: Conversation
    @NSManaged public var createdBy: User
}