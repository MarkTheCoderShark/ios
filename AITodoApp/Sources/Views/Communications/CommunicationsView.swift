import SwiftUI
import CoreData

struct CommunicationsView: View {
    @State private var selectedSegment: CommunicationSegment = .messages

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CommunicationSegmentPicker(selectedSegment: $selectedSegment)

                switch selectedSegment {
                case .notes:
                    NotesView()
                case .gmail:
                    GmailView()
                case .messages:
                    MessagesView()
                }
            }
            .navigationTitle("Communications")
        }
    }
}

enum CommunicationSegment: String, CaseIterable {
    case notes = "Notes"
    case gmail = "Gmail"
    case messages = "Messages"
}

struct CommunicationSegmentPicker: View {
    @Binding var selectedSegment: CommunicationSegment

    var body: some View {
        Picker("Communication Type", selection: $selectedSegment) {
            ForEach(CommunicationSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

struct NotesView: View {
    @State private var notes: [Note] = []
    @State private var showingCreateNote = false

    var body: some View {
        VStack {
            if notes.isEmpty {
                EmptyNotesView()
            } else {
                List(notes) { note in
                    NoteRowView(note: note)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateNote = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateNote) {
            CreateNoteView()
        }
    }
}

struct Note: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let createdAt: Date
    let tags: [String]
}

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
                .fontWeight(.medium)

            Text(note.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            HStack {
                ForEach(note.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }

                Spacer()

                Text(RelativeDateTimeFormatter().localizedString(for: note.createdAt, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyNotesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Notes Yet")
                .font(.headline)
                .fontWeight(.medium)

            Text("Create your first note to capture thoughts and ideas.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct CreateNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    TextField("Title", text: $title)
                    TextField("Content", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section("Tags") {
                    TextField("Tags (comma separated)", text: $tags)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createNote()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }

    private func createNote() {
        dismiss()
    }
}

struct GmailView: View {
    @State private var emails: [Email] = []
    @State private var isConnected = false

    var body: some View {
        VStack {
            if !isConnected {
                GmailConnectionView()
            } else if emails.isEmpty {
                EmptyGmailView()
            } else {
                List(emails) { email in
                    EmailRowView(email: email)
                }
                .refreshable {
                    await refreshEmails()
                }
            }
        }
    }

    private func refreshEmails() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

struct Email: Identifiable {
    let id = UUID()
    let subject: String
    let sender: String
    let preview: String
    let receivedAt: Date
    let isRead: Bool
    let isImportant: Bool
}

struct GmailConnectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Connect Gmail")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect your Gmail account to view and manage emails directly from the app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: connectGmail) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Connect Gmail Account")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }

    private func connectGmail() {
    }
}

struct EmailRowView: View {
    let email: Email

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(email.sender)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(email.isRead ? .secondary : .primary)

                    Text(email.subject)
                        .font(.body)
                        .fontWeight(email.isRead ? .regular : .semibold)
                        .foregroundColor(email.isRead ? .secondary : .primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(RelativeDateTimeFormatter().localizedString(for: email.receivedAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !email.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Text(email.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyGmailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Emails")
                .font(.headline)
                .fontWeight(.medium)

            Text("Your Gmail inbox is empty or emails haven't loaded yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct MessagesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.lastActivityAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default)
    private var conversations: FetchedResults<Conversation>

    @State private var showingNewMessage = false

    var body: some View {
        VStack {
            if conversations.isEmpty {
                EmptyMessagesView()
            } else {
                List {
                    ForEach(conversations, id: \.id) { conversation in
                        NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                            ConversationRowView(conversation: conversation)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewMessage = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewMessage) {
            NewMessageView()
        }
    }
}

struct ConversationRowView: View {
    @ObservedObject var conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ConversationAvatarView(conversation: conversation)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversationTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    if let lastActivity = conversation.lastActivityAt {
                        Text(RelativeDateTimeFormatter().localizedString(for: lastActivity, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("Last message preview...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    if hasUnreadMessages {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }

                    Spacer()

                    if conversation.type == .group {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var conversationTitle: String {
        if let name = conversation.name, !name.isEmpty {
            return name
        }

        if conversation.type == .dm {
            return "Direct Message"
        }

        return "Group Chat"
    }

    private var hasUnreadMessages: Bool {
        false
    }
}

struct ConversationAvatarView: View {
    let conversation: Conversation

    var body: some View {
        if conversation.type == .dm {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        } else {
            Image(systemName: "person.2.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
    }
}

struct EmptyMessagesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Conversations")
                .font(.headline)
                .fontWeight(.medium)

            Text("Start a new conversation to begin messaging with your team.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ConversationDetailView: View {
    @ObservedObject var conversation: Conversation

    var body: some View {
        VStack {
            Text("Conversation Detail View")
                .font(.title2)
                .padding()

            Text("Coming soon! This will show the full conversation with messages, file attachments, and task integration.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .navigationTitle(conversation.name ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("New Message")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Coming soon! This feature will allow you to start new conversations with team members.")
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
    CommunicationsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}