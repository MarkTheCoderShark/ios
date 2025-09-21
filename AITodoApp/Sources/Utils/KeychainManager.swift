import Foundation
import Security

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()

    // MARK: - Constants
    struct ServiceKeys {
        static let appService = "AITodoApp"
        static let gmailAccessToken = "gmail_access_token"
        static let authToken = "auth_token"
        static let userId = "user_id"
    }

    private init() {}

    func save(_ data: Data, service: String, account: String) throws {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecValueData: data
        ] as CFDictionary

        // Delete any existing item
        SecItemDelete(query)

        let status = SecItemAdd(query, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func read(service: String, account: String) throws -> Data {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let passwordData = item as? Data else {
            throw KeychainError.unexpectedPasswordData
        }

        return passwordData
    }

    func delete(service: String, account: String) throws {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        let status = SecItemDelete(query)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // Convenience methods for string storage
    func saveString(_ string: String, service: String, account: String) throws {
        guard let data = string.data(using: .utf8) else { return }
        try save(data, service: service, account: account)
    }

    func readString(service: String, account: String) throws -> String {
        let data = try read(service: service, account: account)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        return string
    }
}