import Foundation

enum ConfigurationKey: String {
    case openAIAPIKey = "OPENAI_API_KEY"
    case googleClientID = "GOOGLE_CLIENT_ID"
    case websocketURL = "WEBSOCKET_URL"
}

class SecureConfiguration {
    static let shared = SecureConfiguration()

    private init() {}

    func getValue(for key: ConfigurationKey) -> String? {
        // First check Info.plist
        if let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String {
            return value
        }

        // Fallback to environment variables (for development)
        return ProcessInfo.processInfo.environment[key.rawValue]
    }

    var openAIAPIKey: String? {
        return getValue(for: .openAIAPIKey)?.isEmpty == false ? getValue(for: .openAIAPIKey) : nil
    }

    var googleClientID: String? {
        return getValue(for: .googleClientID)?.isEmpty == false ? getValue(for: .googleClientID) : nil
    }

    var websocketURL: String {
        getValue(for: .websocketURL) ?? "wss://localhost:3001"
    }
}