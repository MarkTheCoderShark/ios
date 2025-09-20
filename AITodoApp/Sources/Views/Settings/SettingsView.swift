import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthenticationService()

    var body: some View {
        NavigationView {
            List {
                AccountSection()
                IntegrationsSection()
                PreferencesSection()
                NotificationsSection()
                PrivacySection()
                PeopleSection()
                SupportSection()
            }
            .navigationTitle("Settings")
        }
    }
}

struct AccountSection: View {
    var body: some View {
        Section("Account") {
            HStack {
                AsyncImage(url: URL(string: "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("John Doe")
                        .font(.headline)
                        .fontWeight(.medium)

                    Text("john@example.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: AccountDetailView()) {
                    EmptyView()
                }
            }
            .padding(.vertical, 4)

            NavigationLink(destination: AccountDetailView()) {
                SettingsRow(icon: "person.circle", title: "Profile", subtitle: "Manage your profile information")
            }

            Button(action: signOut) {
                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", isDestructive: true)
            }
        }
    }

    private func signOut() {
    }
}

struct IntegrationsSection: View {
    @State private var isGmailConnected = false

    var body: some View {
        Section("Integrations") {
            HStack {
                SettingsRow(icon: "envelope.fill", title: "Gmail", subtitle: isGmailConnected ? "Connected" : "Not connected")

                Spacer()

                Toggle("", isOn: $isGmailConnected)
                    .labelsHidden()
            }

            NavigationLink(destination: IntegrationsDetailView()) {
                SettingsRow(icon: "link", title: "Manage Integrations", subtitle: "Connect external services")
            }
        }
    }
}

struct PreferencesSection: View {
    @State private var workdayStart = Date()
    @State private var workdayEnd = Date()
    @State private var enabledAIBrief = true
    @State private var briefTime = Date()

    var body: some View {
        Section("Preferences") {
            NavigationLink(destination: WorkHoursView()) {
                SettingsRow(icon: "clock", title: "Work Hours", subtitle: "9:00 AM - 5:00 PM")
            }

            HStack {
                SettingsRow(icon: "brain.head.profile", title: "AI Daily Brief", subtitle: "Get AI-generated daily summaries")

                Spacer()

                Toggle("", isOn: $enabledAIBrief)
                    .labelsHidden()
            }

            if enabledAIBrief {
                NavigationLink(destination: BriefSettingsView()) {
                    SettingsRow(icon: "calendar.badge.clock", title: "Brief Time", subtitle: "8:00 AM daily")
                }
            }

            NavigationLink(destination: PreferencesDetailView()) {
                SettingsRow(icon: "slider.horizontal.3", title: "General Preferences", subtitle: "Customize app behavior")
            }
        }
    }
}

struct NotificationsSection: View {
    @State private var notificationsEnabled = true
    @State private var taskReminders = true
    @State private var messageNotifications = true
    @State private var mentionNotifications = true

    var body: some View {
        Section("Notifications") {
            HStack {
                SettingsRow(icon: "bell", title: "Notifications", subtitle: "Allow notifications")

                Spacer()

                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }

            if notificationsEnabled {
                HStack {
                    SettingsRow(icon: "checkmark.circle", title: "Task Reminders", subtitle: "Due date and deadline alerts")

                    Spacer()

                    Toggle("", isOn: $taskReminders)
                        .labelsHidden()
                }

                HStack {
                    SettingsRow(icon: "message", title: "Messages", subtitle: "New message notifications")

                    Spacer()

                    Toggle("", isOn: $messageNotifications)
                        .labelsHidden()
                }

                HStack {
                    SettingsRow(icon: "at.badge.plus", title: "Mentions", subtitle: "When you're mentioned")

                    Spacer()

                    Toggle("", isOn: $mentionNotifications)
                        .labelsHidden()
                }

                NavigationLink(destination: NotificationDetailView()) {
                    SettingsRow(icon: "bell.badge", title: "Advanced Notifications", subtitle: "Quiet hours, per-thread settings")
                }
            }
        }
    }
}

struct PrivacySection: View {
    @State private var readReceipts = true
    @State private var activityStatus = true

    var body: some View {
        Section("Privacy & Data") {
            HStack {
                SettingsRow(icon: "eye", title: "Read Receipts", subtitle: "Show when you've read messages")

                Spacer()

                Toggle("", isOn: $readReceipts)
                    .labelsHidden()
            }

            HStack {
                SettingsRow(icon: "circle.fill", title: "Activity Status", subtitle: "Show when you're active")

                Spacer()

                Toggle("", isOn: $activityStatus)
                    .labelsHidden()
            }

            NavigationLink(destination: PrivacyDetailView()) {
                SettingsRow(icon: "hand.raised", title: "Privacy Settings", subtitle: "Data usage and privacy controls")
            }

            NavigationLink(destination: DataManagementView()) {
                SettingsRow(icon: "externaldrive", title: "Data Management", subtitle: "Export and delete your data")
            }
        }
    }
}

struct PeopleSection: View {
    var body: some View {
        Section("People & Teams") {
            NavigationLink(destination: PeopleManagementView()) {
                SettingsRow(icon: "person.2", title: "Team Members", subtitle: "Manage team and contacts")
            }

            NavigationLink(destination: InviteView()) {
                SettingsRow(icon: "envelope.badge.person.crop", title: "Send Invites", subtitle: "Invite people to join")
            }

            NavigationLink(destination: PermissionsView()) {
                SettingsRow(icon: "key", title: "Permissions", subtitle: "Default roles and access")
            }
        }
    }
}

struct SupportSection: View {
    var body: some View {
        Section("Support") {
            NavigationLink(destination: HelpView()) {
                SettingsRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "FAQs and contact support")
            }

            NavigationLink(destination: AboutView()) {
                SettingsRow(icon: "info.circle", title: "About", subtitle: "Version 1.0.0")
            }

            Button(action: sendFeedback) {
                SettingsRow(icon: "envelope", title: "Send Feedback", subtitle: "Help us improve the app")
            }
        }
    }

    private func sendFeedback() {
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isDestructive: Bool

    init(icon: String, title: String, subtitle: String? = nil, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isDestructive ? .red : .blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct AccountDetailView: View {
    var body: some View {
        PlaceholderDetailView(title: "Account Details", description: "Manage your profile information, change password, and update account settings.")
    }
}

struct IntegrationsDetailView: View {
    var body: some View {
        PlaceholderDetailView(title: "Integrations", description: "Connect and manage external services like Gmail, calendar apps, and other productivity tools.")
    }
}

struct WorkHoursView: View {
    var body: some View {
        PlaceholderDetailView(title: "Work Hours", description: "Set your working hours to help the AI assistant provide better recommendations and scheduling.")
    }
}

struct BriefSettingsView: View {
    var body: some View {
        PlaceholderDetailView(title: "Brief Settings", description: "Customize when and how you receive your daily AI-generated brief.")
    }
}

struct PreferencesDetailView: View {
    var body: some View {
        PlaceholderDetailView(title: "Preferences", description: "Customize app behavior, themes, and general settings.")
    }
}

struct NotificationDetailView: View {
    var body: some View {
        PlaceholderDetailView(title: "Notification Settings", description: "Configure detailed notification preferences, quiet hours, and per-conversation settings.")
    }
}

struct PrivacyDetailView: View {
    var body: some View {
        PlaceholderDetailView(title: "Privacy Settings", description: "Control how your data is used and shared within the app.")
    }
}

struct DataManagementView: View {
    var body: some View {
        PlaceholderDetailView(title: "Data Management", description: "Export your data, manage storage, and delete account information.")
    }
}

struct PeopleManagementView: View {
    var body: some View {
        PlaceholderDetailView(title: "Team Members", description: "Manage your team members, view contact directory, and organize your workspace.")
    }
}

struct InviteView: View {
    var body: some View {
        PlaceholderDetailView(title: "Send Invites", description: "Invite team members and collaborators to join your workspace.")
    }
}

struct PermissionsView: View {
    var body: some View {
        PlaceholderDetailView(title: "Permissions", description: "Set default roles and permissions for new team members and projects.")
    }
}

struct HelpView: View {
    var body: some View {
        PlaceholderDetailView(title: "Help & Support", description: "Find answers to common questions and get support from our team.")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("AI Todo & Communications")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .font(.body)
                .foregroundColor(.secondary)

            Text("A modern productivity app with AI-powered task management, team messaging, and intelligent insights.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaceholderDetailView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Under Construction")
                .font(.title2)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}