import SwiftUI

// MARK: - SwiftUI Performance Helpers

/// Performance-optimized view builder for conditional content
struct ConditionalContent<TrueContent: View, FalseContent: View>: View {
    let condition: Bool
    let trueContent: () -> TrueContent
    let falseContent: () -> FalseContent

    init(
        _ condition: Bool,
        @ViewBuilder then trueContent: @escaping () -> TrueContent,
        @ViewBuilder else falseContent: @escaping () -> FalseContent
    ) {
        self.condition = condition
        self.trueContent = trueContent
        self.falseContent = falseContent
    }

    var body: some View {
        if condition {
            trueContent()
        } else {
            falseContent()
        }
    }
}

// MARK: - View Modifiers

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isLoading)
            .overlay(
                LoadingView()
                    .opacity(isLoading ? 1 : 0)
            )
    }
}

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

// MARK: - View Extensions

extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }

    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissModifier())
    }

    /// Applies iOS 13 compatible sheet presentation
    @available(iOS 13.0, *)
    func compatibleSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(iOS 14.0, *) {
            return self.sheet(isPresented: isPresented, content: content)
        } else {
            return self.sheet(isPresented: isPresented, content: content)
        }
    }

    /// Applies adaptive navigation for iPhone/iPad
    func adaptiveNavigation() -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationView {
                    self
                }
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
            } else {
                NavigationView {
                    self
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

// MARK: - Custom View Components

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Accessibility Helpers

extension View {
    func accessibilityElement(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    func accessibilityAction(
        named name: String,
        action: @escaping () -> Void
    ) -> some View {
        self.accessibilityAction(named: Text(name), action)
    }
}