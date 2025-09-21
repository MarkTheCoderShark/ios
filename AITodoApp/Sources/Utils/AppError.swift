import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case dataError(String)
    case validationError(String)
    case coreDataError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .coreDataError(let message):
            return "Database Error: \(message)"
        case .unknownError:
            return "An unexpected error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please sign in again to continue."
        case .dataError:
            return "There was an issue with your data. Please try again."
        case .validationError:
            return "Please check your input and try again."
        case .coreDataError:
            return "There was a database error. Please restart the app."
        case .unknownError:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// Error handling view modifier
import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(error.localizedDescription)
                    .font(.body)
                +
                Text("\n\n")
                    .font(.caption)
                +
                Text(error.recoverySuggestion ?? "")
                    .font(.caption)
            }
    }
}

extension View {
    func errorAlert(error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}