import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)],
        predicate: NSPredicate(format: "statusRaw != %@", TaskStatus.completed.rawValue),
        animation: .default)
    private var tasks: FetchedResults<Task>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    DailyBriefCard()
                    TopTasksCard(tasks: Array(tasks.prefix(3)))
                    InboxSnapshotCard()
                    UniversalCaptureCard()
                }
                .padding()
            }
            .navigationTitle("Home")
            .refreshable {
                await refreshData()
            }
        }
    }

    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

struct DailyBriefCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("AI Daily Brief")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Good morning! You have 3 tasks due today and 2 unread messages. Your focus time is scheduled from 9-11 AM.")
                .font(.body)
                .foregroundColor(.primary)

            HStack {
                Button(action: {}) {
                    Text("View Full Brief")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TopTasksCard: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Top 3 Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: TasksView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if tasks.isEmpty {
                Text("No tasks yet. Tap + to create your first task!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct InboxSnapshotCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.fill")
                    .foregroundColor(.green)
                Text("Inbox Snapshot")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: CommunicationsView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("5 new emails")
                    Spacer()
                    Text("2h ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.green)
                    Text("3 new messages")
                    Spacer()
                    Text("30m ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "at.badge.plus")
                        .foregroundColor(.orange)
                    Text("2 mentions")
                    Spacer()
                    Text("1h ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct UniversalCaptureCard: View {
    @State private var quickNote = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.purple)
                Text("Quick Capture")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack {
                TextField("What's on your mind?", text: $quickNote)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    captureQuickNote()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            HStack {
                Button(action: {}) {
                    Label("Task", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: {}) {
                    Label("Note", systemImage: "note.text")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: {}) {
                    Label("Voice", systemImage: "mic.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func captureQuickNote() {
        if !quickNote.isEmpty {
            quickNote = ""
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}