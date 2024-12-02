import Foundation
import Security

public final class KeychainHelper {
    public static let standard = KeychainHelper()
    private init() {}

    public func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]

            SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
        } else if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }

    public func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        return (status == errSecSuccess) ? (result as? Data) : nil
    }

    public func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Authentication Specific Methods
extension KeychainHelper {
    public func saveAuthToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        save(data, service: "com.caringmind.auth", account: "authToken")
    }

    public func getAuthToken() -> String? {
        guard let data = read(service: "com.caringmind.auth", account: "authToken") else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAuthToken() {
        delete(service: "com.caringmind.auth", account: "authToken")
    }
}

// MARK: - Google Account ID Methods
extension KeychainHelper {
    public func saveGoogleAccountID(_ id: String) {
        guard let data = id.data(using: .utf8) else { return }
        save(data, service: "com.caringmind.auth", account: "googleID")
    }

    public func getGoogleAccountID() -> String? {
        guard let data = read(service: "com.caringmind.auth", account: "googleID") else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteGoogleAccountID() {
        delete(service: "com.caringmind.auth", account: "googleID")
    }
}
