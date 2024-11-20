//
//  KeychainHelper.swift
//  CaringMind
//
//  Provides secure storage and retrieval of sensitive data using Keychain.
//

import Foundation // Ensure Foundation is imported

struct KeychainHelper {
    static let standard = KeychainHelper()

    /// Saves data to the Keychain for a specific service and account.
    /// - Parameters:
    ///   - data: The data to save as a string.
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    func save(_ data: String, service: String, account: String) {
        guard let data = data.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Reads data from the Keychain for a specific service and account.
    /// - Parameters:
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    /// - Returns: The retrieved data as a string, or `nil` if not found.
    func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr, let data = dataTypeRef as? Data, let uuid = String(data: data, encoding: .utf8) {
            return uuid
        }
        return nil
    }

    /// Deletes data from the Keychain for a specific service and account.
    /// - Parameters:
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}


extension KeychainHelper {
    /// Saves the Google Account ID to the Keychain.
    func saveGoogleAccountID(_ id: String) {
        save(id, service: "CaringMindService", account: "GoogleAccountID")
    }
    
    /// Retrieves the Google Account ID from the Keychain.
    func getGoogleAccountID() -> String? {
        return read(service: "CaringMindService", account: "GoogleAccountID")
    }
}
