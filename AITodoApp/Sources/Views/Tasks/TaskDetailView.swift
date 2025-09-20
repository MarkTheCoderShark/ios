import SwiftUI
import CoreData

struct TaskDetailView: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTask = false
    @State private var showingShareTask = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TaskHeaderView(task: task)
                TaskInfoSection(task: task)
                TaskAssignmentSection(task: task)
                TaskActivitySection(task: task)
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditTask = true }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    if task.isShared {
                        Button(action: { showingShareTask = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button(role: .destructive, action: deleteTask) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task)
        }
        .sheet(isPresented: $showingShareTask) {
            ShareTaskView(task: task)
        }
    }

    private func deleteTask() {
        withAnimation {
            viewContext.delete(task)

            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TaskHeaderView: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: toggleTaskStatus) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(task.status == .completed ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .strikethrough(task.status == .completed)

                    HStack {
                        TaskPriorityBadge(priority: task.priority)
                        TaskStatusBadge(status: task.status)

                        if task.isShared {
                            Label("Shared", systemImage: "person.2")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()
            }

            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
}

struct TaskStatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

struct TaskInfoSection: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                if let dueDate = task.dueDate {
                    InfoRow(icon: "calendar", title: "Due Date", value: formatDate(dueDate))
                }

                if let project = task.project {
                    InfoRow(icon: "folder", title: "Project", value: project.name)
                }

                if task.estimatedDuration > 0 {
                    InfoRow(icon: "clock", title: "Estimated Duration",
                           value: "\(task.estimatedDuration) minutes")
                }

                InfoRow(icon: "person", title: "Created by", value: task.owner.displayName)
                InfoRow(icon: "clock.arrow.circlepath", title: "Created",
                       value: formatDate(task.createdAt))

                if let completedAt = task.completedAt {
                    InfoRow(icon: "checkmark.circle", title: "Completed",
                           value: formatDate(completedAt))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(title)
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

struct TaskAssignmentSection: View {
    let task: Task

    var body: some View {
        if task.isShared {
            VStack(alignment: .leading, spacing: 12) {
                Text("People")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text("Owner")
                        Spacer()
                        Text(task.owner.displayName)
                            .fontWeight(.medium)
                    }

                    if let assignees = task.assignees?.allObjects as? [User], !assignees.isEmpty {
                        ForEach(assignees, id: \.id) { assignee in
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.green)
                                Text("Assignee")
                                Spacer()
                                Text(assignee.displayName)
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    if let followers = task.followers?.allObjects as? [User], !followers.isEmpty {
                        ForEach(followers, id: \.id) { follower in
                            HStack {
                                Image(systemName: "eye.circle")
                                    .foregroundColor(.orange)
                                Text("Follower")
                                Spacer()
                                Text(follower.displayName)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TaskActivitySection: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .fontWeight(.semibold)

            if let conversationLinks = task.conversationLinks?.allObjects as? [TaskConversationLink],
               !conversationLinks.isEmpty {
                ForEach(conversationLinks, id: \.objectID) { link in
                    HStack {
                        Image(systemName: "message.circle")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text("Linked to conversation")
                                .font(.body)
                            Text("Added by \(link.createdBy.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(formatDate(link.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No activity yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        TaskDetailView(task: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Task }) as! Task)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}