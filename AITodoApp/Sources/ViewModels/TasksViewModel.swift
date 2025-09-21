import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var searchText = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var isLoading = false
    @Published var error: AppError?

    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext

    enum TaskFilter {
        case all, pending, completed, overdue
    }

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupBindings()
        fetchTasks()
    }

    private func setupBindings() {
        // Debounce search to avoid excessive fetches
        Publishers.CombineLatest($searchText, $selectedFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates { previous, current in
                previous.0 == current.0 && previous.1 == current.1
            }
            .sink { [weak self] _ in
                self?.fetchTasks()
            }
            .store(in: &cancellables)
    }

    func fetchTasks() {
        isLoading = true
        error = nil

        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)]

        // Build predicate based on filter and search
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText))
        }

        switch selectedFilter {
        case .pending:
            predicates.append(NSPredicate(format: "statusRaw == %@", TaskStatus.pending.rawValue))
        case .completed:
            predicates.append(NSPredicate(format: "statusRaw == %@", TaskStatus.completed.rawValue))
        case .overdue:
            predicates.append(NSPredicate(format: "dueDate < %@ AND statusRaw != %@", Date() as NSDate, TaskStatus.completed.rawValue))
        case .all:
            break
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        do {
            tasks = try context.fetch(request)
            isLoading = false
        } catch {
            self.error = .coreDataError("Failed to fetch tasks: \(error.localizedDescription)")
            isLoading = false
        }
    }

    func createTask(title: String, description: String, priority: String, dueDate: Date) async {
        guard validateTaskInput(title: title) else {
            error = .validationError("Task title is required and must be less than 100 characters")
            return
        }

        let backgroundContext = PersistenceController.shared.backgroundContext()

        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }

            let newTask = Task(context: backgroundContext)
            newTask.id = UUID()
            newTask.title = title
            newTask.notes = description
            newTask.priority = TaskPriority(rawValue: priority) ?? .medium
            newTask.dueDate = dueDate
            newTask.status = .pending
            newTask.createdAt = Date()
            newTask.updatedAt = Date()

            // Get current user safely
            if let currentUser = self.getCurrentUser(in: backgroundContext) {
                newTask.owner = currentUser
            }

            do {
                try backgroundContext.save()
                await MainActor.run {
                    self.fetchTasks()
                }
            } catch {
                await MainActor.run {
                    self.error = .coreDataError("Failed to create task: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateTask(_ task: Task) async {
        let backgroundContext = PersistenceController.shared.backgroundContext()
        let taskObjectID = task.objectID

        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }

            do {
                let taskInBackground = try backgroundContext.existingObject(with: taskObjectID) as? Task
                taskInBackground?.updatedAt = Date()

                try backgroundContext.save()
                await MainActor.run {
                    self.fetchTasks()
                }
            } catch {
                await MainActor.run {
                    self.error = .coreDataError("Failed to update task: \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteTask(_ task: Task) async {
        let backgroundContext = PersistenceController.shared.backgroundContext()
        let taskObjectID = task.objectID

        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }

            do {
                if let taskInBackground = try backgroundContext.existingObject(with: taskObjectID) as? Task {
                    backgroundContext.delete(taskInBackground)
                    try backgroundContext.save()
                }

                await MainActor.run {
                    self.fetchTasks()
                }
            } catch {
                await MainActor.run {
                    self.error = .coreDataError("Failed to delete task: \(error.localizedDescription)")
                }
            }
        }
    }

    private func validateTaskInput(title: String) -> Bool {
        return !title.isEmpty && title.count <= 100
    }

    private func getCurrentUser(in context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "isActive == YES")

        return try? context.fetch(request).first
    }
}