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

    var openAIAPIKey: String {
        guard let key = getValue(for: .openAIAPIKey), !key.isEmpty else {
            fatalError("OpenAI API Key not configured. Add \(ConfigurationKey.openAIAPIKey.rawValue) to Info.plist")
        }
        return key
    }

    var googleClientID: String {
        guard let id = getValue(for: .googleClientID), !id.isEmpty else {
            fatalError("Google Client ID not configured. Add \(ConfigurationKey.googleClientID.rawValue) to Info.plist")
        }
        return id
    }

    var websocketURL: String {
        getValue(for: .websocketURL) ?? "wss://localhost:3001"
    }
}