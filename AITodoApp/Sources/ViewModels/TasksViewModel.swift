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
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchTasks()
            }
            .store(in: &cancellables)

        $selectedFilter
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
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@", searchText, searchText))
        }

        switch selectedFilter {
        case .pending:
            predicates.append(NSPredicate(format: "status == %@", "pending"))
        case .completed:
            predicates.append(NSPredicate(format: "status == %@", "completed"))
        case .overdue:
            predicates.append(NSPredicate(format: "dueDate < %@ AND status != %@", Date() as NSDate, "completed"))
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

        await context.perform { [weak self] in
            guard let self = self else { return }

            let newTask = Task(context: self.context)
            newTask.id = UUID()
            newTask.title = title
            newTask.taskDescription = description
            newTask.priority = priority
            newTask.dueDate = dueDate
            newTask.status = "pending"
            newTask.createdAt = Date()

            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .coreDataError("Failed to create task: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateTask(_ task: Task) async {
        await context.perform { [weak self] in
            guard let self = self else { return }

            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .coreDataError("Failed to update task: \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteTask(_ task: Task) async {
        await context.perform { [weak self] in
            guard let self = self else { return }

            self.context.delete(task)

            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .coreDataError("Failed to delete task: \(error.localizedDescription)")
                }
            }
        }
    }

    private func validateTaskInput(title: String) -> Bool {
        return !title.isEmpty && title.count <= 100
    }
}