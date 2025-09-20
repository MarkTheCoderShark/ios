import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userDefaults = UserDefaults.standard
    private let authTokenKey = "auth_token"
    private let userIdKey = "user_id"

    init() {
        checkAuthenticationState()
    }

    func checkAuthenticationState() {
        let hasToken = userDefaults.string(forKey: authTokenKey) != nil
        let hasUserId = userDefaults.string(forKey: userIdKey) != nil

        DispatchQueue.main.async {
            self.isAuthenticated = hasToken && hasUserId
        }

        if isAuthenticated {
            loadCurrentUser()
        }
    }

    @MainActor
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let result = try await ASAuthorizationController(authorizationRequests: [request]).performRequests()

            if let credential = result.first?.credential as? ASAuthorizationAppleIDCredential {
                await handleAppleSignIn(credential: credential)
            }
        } catch {
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            errorMessage = "Unable to present Google Sign In"
            isLoading = false
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            await handleGoogleSignIn(result: result)
        } catch {
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        let email = credential.email ?? "apple_user@example.com"
        let fullName = credential.fullName
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        await createUser(email: email, displayName: displayName.isEmpty ? "Apple User" : displayName, provider: "apple")
    }

    private func handleGoogleSignIn(result: GIDSignInResult) async {
        let user = result.user
        let email = user.profile?.email ?? "google_user@example.com"
        let displayName = user.profile?.name ?? "Google User"

        await createUser(email: email, displayName: displayName, provider: "google")
    }

    private func createUser(email: String, displayName: String, provider: String) async {
        let token = UUID().uuidString
        let userId = UUID().uuidString

        userDefaults.set(token, forKey: authTokenKey)
        userDefaults.set(userId, forKey: userIdKey)

        await MainActor.run {
            self.isAuthenticated = true
            self.isLoading = false
        }

        createUserInCoreData(userId: userId, email: email, displayName: displayName)
    }

    private func createUserInCoreData(userId: String, email: String, displayName: String) {
        let context = PersistenceController.shared.backgroundContext()

        context.perform {
            let user = User(context: context)
            user.id = UUID(uuidString: userId) ?? UUID()
            user.email = email
            user.displayName = displayName
            user.createdAt = Date()
            user.updatedAt = Date()
            user.isActive = true

            do {
                try context.save()
            } catch {
                print("Failed to save user: \(error)")
            }
        }
    }

    private func loadCurrentUser() {
        guard let userIdString = userDefaults.string(forKey: userIdKey),
              let userId = UUID(uuidString: userIdString) else {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        request.fetchLimit = 1

        do {
            let users = try context.fetch(request)
            DispatchQueue.main.async {
                self.currentUser = users.first
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }

    func signOut() {
        userDefaults.removeObject(forKey: authTokenKey)
        userDefaults.removeObject(forKey: userIdKey)

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
}

extension ASAuthorizationController {
    func performRequests() async throws -> [ASAuthorizationResult] {
        return try await withCheckedThrowingContinuation { continuation in
            self.delegate = AuthorizationDelegate(continuation: continuation)
            self.performRequests()
        }
    }
}

private class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let continuation: CheckedContinuation<[ASAuthorizationResult], Error>

    init(continuation: CheckedContinuation<[ASAuthorizationResult], Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: [ASAuthorizationResult(credential: authorization.credential)])
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

struct ASAuthorizationResult {
    let credential: ASAuthorizationCredential

    init(credential: ASAuthorizationCredential) {
        self.credential = credential
    }
}