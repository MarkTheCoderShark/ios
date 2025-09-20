import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @StateObject private var authService = AuthenticationService()

    var body: some View {
        ZStack {
            if currentPage < onboardingPages.count {
                OnboardingPageView(
                    page: onboardingPages[currentPage],
                    currentPage: $currentPage,
                    totalPages: onboardingPages.count
                )
            } else {
                SignInView()
                    .environmentObject(authService)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to AI Todo",
            subtitle: "Your intelligent productivity companion",
            description: "Organize tasks, manage communications, and boost productivity with AI-powered insights.",
            imageName: "brain.head.profile",
            primaryColor: .blue
        ),
        OnboardingPage(
            title: "Smart Task Management",
            subtitle: "Stay organized with intelligent features",
            description: "Create tasks, set priorities, track progress, and let AI help you plan your perfect day.",
            imageName: "checkmark.circle.fill",
            primaryColor: .green
        ),
        OnboardingPage(
            title: "Team Collaboration",
            subtitle: "Work better together",
            description: "Share tasks, communicate in real-time, and coordinate projects with your team seamlessly.",
            imageName: "person.2.fill",
            primaryColor: .orange
        ),
        OnboardingPage(
            title: "AI-Powered Insights",
            subtitle: "Let intelligence guide your productivity",
            description: "Get daily briefs, email summaries, task suggestions, and productivity insights powered by AI.",
            imageName: "sparkles",
            primaryColor: .purple
        )
    ]
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var currentPage: Int
    let totalPages: Int

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 30) {
                Image(systemName: page.imageName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(page.primaryColor)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(page.subtitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            VStack(spacing: 20) {
                PageIndicator(currentPage: currentPage, totalPages: totalPages)

                Button(action: nextPage) {
                    Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(page.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                if currentPage > 0 {
                    Button(action: previousPage) {
                        Text("Back")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
    }

    private func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        } else {
            currentPage = totalPages
        }
    }

    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Choose your preferred sign-in method to get started with AI Todo.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton()
                    .onTapGesture {
                        Task {
                            await authService.signInWithApple()
                        }
                    }

                SignInWithGoogleButton()
                    .onTapGesture {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    }
            }
            .padding(.horizontal, 40)
            .disabled(authService.isLoading)

            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("By signing in, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Button("Terms of Service") {}
                        .font(.caption)

                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Privacy Policy") {}
                        .font(.caption)
                }
            }
            .padding(.bottom, 20)
        }
        .overlay(
            Group {
                if authService.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }
}

struct SignInWithAppleButton: View {
    var body: some View {
        HStack {
            Image(systemName: "applelogo")
                .font(.title2)

            Text("Continue with Apple")
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

struct SignInWithGoogleButton: View {
    var body: some View {
        HStack {
            Image(systemName: "globe")
                .font(.title2)

            Text("Continue with Google")
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .foregroundColor(.primary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView()
}