import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainService = KeychainManager.ServiceKeys.appService
    private let authTokenKey = KeychainManager.ServiceKeys.authToken
    private let userIdKey = KeychainManager.ServiceKeys.userId

    init() {
        checkAuthenticationState()
    }

    func checkAuthenticationState() {
        let hasToken = (try? KeychainManager.shared.readString(service: keychainService, account: authTokenKey)) != nil
        let hasUserId = (try? KeychainManager.shared.readString(service: keychainService, account: userIdKey)) != nil

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

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
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
        let email = credential.email ?? "apple_user_\(credential.user)@private.apple.com"
        let fullName = credential.fullName
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        await createUser(email: email, displayName: displayName.isEmpty ? "Apple User" : displayName, provider: "apple")
    }

    private func handleGoogleSignIn(result: GIDSignInResult) async {
        let user = result.user
        let email = user.profile?.email ?? "user_\(user.userID ?? "unknown")@gmail.com"
        let displayName = user.profile?.name ?? "Google User"

        await createUser(email: email, displayName: displayName, provider: "google")
    }

    private func createUser(email: String, displayName: String, provider: String) async {
        let token = UUID().uuidString
        let userId = UUID().uuidString

        try? KeychainManager.shared.saveString(token, service: keychainService, account: authTokenKey)
        try? KeychainManager.shared.saveString(userId, service: keychainService, account: userIdKey)

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
        guard let userIdString = try? KeychainManager.shared.readString(service: keychainService, account: userIdKey),
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
        try? KeychainManager.shared.delete(service: keychainService, account: authTokenKey)
        try? KeychainManager.shared.delete(service: keychainService, account: userIdKey)

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
}

extension ASAuthorizationController {
    func performRequests() async throws -> [ASAuthorizationResult] {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AuthorizationDelegate(continuation: continuation)
            self.delegate = delegate
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