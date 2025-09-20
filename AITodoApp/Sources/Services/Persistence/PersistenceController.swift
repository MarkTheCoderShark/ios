import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let sampleUser = User(context: viewContext)
        sampleUser.id = UUID()
        sampleUser.email = "john@example.com"
        sampleUser.displayName = "John Doe"
        sampleUser.createdAt = Date()
        sampleUser.updatedAt = Date()
        sampleUser.isActive = true

        let sampleProject = Project(context: viewContext)
        sampleProject.id = UUID()
        sampleProject.name = "Sample Project"
        sampleProject.projectDescription = "A sample project for preview"
        sampleProject.visibility = .private
        sampleProject.createdAt = Date()
        sampleProject.updatedAt = Date()
        sampleProject.isArchived = false
        sampleProject.owner = sampleUser

        let sampleTask = Task(context: viewContext)
        sampleTask.id = UUID()
        sampleTask.title = "Complete onboarding"
        sampleTask.notes = "Finish the user onboarding flow"
        sampleTask.status = .pending
        sampleTask.priority = .high
        sampleTask.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        sampleTask.createdAt = Date()
        sampleTask.updatedAt = Date()
        sampleTask.isShared = false
        sampleTask.estimatedDuration = 120
        sampleTask.owner = sampleUser
        sampleTask.project = sampleProject

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func backgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}