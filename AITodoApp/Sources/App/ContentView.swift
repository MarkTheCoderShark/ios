import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authenticationService = AuthenticationService()

    var body: some View {
        Group {
            if authenticationService.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            authenticationService.checkAuthenticationState()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}