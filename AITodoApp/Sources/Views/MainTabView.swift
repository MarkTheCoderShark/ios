import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            TasksView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Tasks")
                }
                .tag(1)

            CommunicationsView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Comms")
                }
                .tag(2)

            AssistantView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Assistant")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}