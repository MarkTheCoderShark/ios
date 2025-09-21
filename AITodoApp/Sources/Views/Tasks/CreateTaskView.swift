import SwiftUI
import CoreData

struct CreateTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var estimatedDuration: Int = 30
    @State private var selectedProject: Project?
    @State private var isShared = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default)
    private var projects: FetchedResults<Project>

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                        .font(.body)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                }

                Section("Priority & Timing") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }

                    Toggle("Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }

                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Picker("Duration", selection: $estimatedDuration) {
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("Half day").tag(240)
                            Text("Full day").tag(480)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section("Organization") {
                    Picker("Project", selection: $selectedProject) {
                        Text("No Project").tag(Project?.none)
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }

                    Toggle("Shared Task", isOn: $isShared)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func createTask() {
        withAnimation {
            let newTask = Task(context: viewContext)
            newTask.id = UUID()
            newTask.title = title
            newTask.notes = notes.isEmpty ? nil : notes
            newTask.status = .pending
            newTask.priority = priority
            newTask.dueDate = hasDueDate ? dueDate : nil
            newTask.estimatedDuration = Int32(estimatedDuration)
            newTask.isShared = isShared
            newTask.createdAt = Date()
            newTask.updatedAt = Date()

            if let currentUser = getCurrentUser() {
                newTask.owner = currentUser
            }

            if let project = selectedProject {
                newTask.project = project
            }

            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Failed to create task: \(error.localizedDescription)")
                // TODO: Show error alert to user
            }
        }
    }

    private func getCurrentUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        do {
            let users = try viewContext.fetch(request)
            return users.first
        } catch {
            return nil
        }
    }
}

struct EditTaskView: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var priority: TaskPriority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var estimatedDuration: Int
    @State private var selectedProject: Project?
    @State private var isShared: Bool

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default)
    private var projects: FetchedResults<Project>

    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes ?? "")
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _estimatedDuration = State(initialValue: Int(task.estimatedDuration))
        _selectedProject = State(initialValue: task.project)
        _isShared = State(initialValue: task.isShared)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                        .font(.body)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                }

                Section("Priority & Timing") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }

                    Toggle("Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }

                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Picker("Duration", selection: $estimatedDuration) {
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("Half day").tag(240)
                            Text("Full day").tag(480)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Section("Organization") {
                    Picker("Project", selection: $selectedProject) {
                        Text("No Project").tag(Project?.none)
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }

                    Toggle("Shared Task", isOn: $isShared)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        withAnimation {
            task.title = title
            task.notes = notes.isEmpty ? nil : notes
            task.priority = priority
            task.dueDate = hasDueDate ? dueDate : nil
            task.estimatedDuration = Int32(estimatedDuration)
            task.isShared = isShared
            task.updatedAt = Date()
            task.project = selectedProject

            do {
                try viewContext.save()
                dismiss()
            } catch {
                print("Failed to create task: \(error.localizedDescription)")
                // TODO: Show error alert to user
            }
        }
    }
}

struct ShareTaskView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Task")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Coming soon! This feature will allow you to share tasks with team members and collaborators.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateTaskView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}