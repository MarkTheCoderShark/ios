import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFilter: TaskFilter = .inbox
    @State private var showingCreateTask = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TaskFilterBar(selectedFilter: $selectedFilter)

                TaskListView(filter: selectedFilter, searchText: searchText)
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView()
            }
        }
    }
}

enum TaskFilter: String, CaseIterable {
    case inbox = "Inbox"
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"
    case projects = "Projects"

    var predicate: NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        switch self {
        case .inbox:
            return NSPredicate(format: "statusRaw != %@ AND project == nil", TaskStatus.completed.rawValue)
        case .today:
            return NSPredicate(format: "statusRaw != %@ AND dueDate >= %@ AND dueDate < %@",
                             TaskStatus.completed.rawValue, today as NSDate, tomorrow as NSDate)
        case .upcoming:
            return NSPredicate(format: "statusRaw != %@ AND dueDate >= %@",
                             TaskStatus.completed.rawValue, tomorrow as NSDate)
        case .completed:
            return NSPredicate(format: "statusRaw == %@", TaskStatus.completed.rawValue)
        case .projects:
            return NSPredicate(format: "project != nil")
        }
    }
}

struct TaskFilterBar: View {
    @Binding var selectedFilter: TaskFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let filter: TaskFilter
    let searchText: String

    @FetchRequest var tasks: FetchedResults<Task>

    init(filter: TaskFilter, searchText: String) {
        self.filter = filter
        self.searchText = searchText

        var predicate = filter.predicate
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@",
                                            searchText, searchText)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, searchPredicate])
        }

        self._tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Task.priorityRaw, ascending: false),
                NSSortDescriptor(keyPath: \Task.dueDate, ascending: true),
                NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)
            ],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        List {
            if tasks.isEmpty {
                EmptyTasksView(filter: filter)
            } else {
                ForEach(tasks, id: \.id) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task)
                    }
                }
                .onDelete(perform: deleteTasks)
            }
        }
        .listStyle(PlainListStyle())
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TaskRowView: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleTaskStatus) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let dueDate = task.dueDate {
                        Label(dueDateText(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }

                    if task.isShared {
                        Label("Shared", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    TaskPriorityBadge(priority: task.priority)

                    Spacer()
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func toggleTaskStatus() {
        withAnimation {
            if task.status == .completed {
                task.status = .pending
                task.completedAt = nil
            } else {
                task.status = .completed
                task.completedAt = Date()
            }
            task.updatedAt = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func dueDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && task.status != .completed
    }
}

struct TaskPriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        if priority != .medium {
            Text(priority.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor.opacity(0.2))
                .foregroundColor(priorityColor)
                .cornerRadius(4)
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .low:
            return .blue
        case .medium:
            return .gray
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

struct EmptyTasksView: View {
    let filter: TaskFilter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text(emptyTitle)
                .font(.headline)
                .fontWeight(.medium)

            Text(emptySubtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var emptyIcon: String {
        switch filter {
        case .inbox:
            return "tray"
        case .today:
            return "calendar"
        case .upcoming:
            return "clock"
        case .completed:
            return "checkmark.circle"
        case .projects:
            return "folder"
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .inbox:
            return "Inbox is Empty"
        case .today:
            return "No Tasks Today"
        case .upcoming:
            return "No Upcoming Tasks"
        case .completed:
            return "No Completed Tasks"
        case .projects:
            return "No Project Tasks"
        }
    }

    private var emptySubtitle: String {
        switch filter {
        case .inbox:
            return "Create your first task to get started with organizing your work."
        case .today:
            return "You're all caught up for today! Enjoy your free time."
        case .upcoming:
            return "No upcoming deadlines. You're staying on top of things!"
        case .completed:
            return "Complete some tasks to see them here."
        case .projects:
            return "Create a project and add tasks to organize your work better."
        }
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}