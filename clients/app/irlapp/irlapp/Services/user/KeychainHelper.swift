//
//  KeychainHelper.swift
//  CaringMind
//
//  Provides secure storage and retrieval of sensitive data using Keychain.
//

import Foundation

struct KeychainHelper {
    static let standard = KeychainHelper()

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
    func saveGoogleAccountID(_ id: String) {
        save(id, service: Constants.googleAccountIDService, account: Constants.googleAccountIDAccount)
    }
    
    func getGoogleAccountID() -> String? {
        return read(service: Constants.googleAccountIDService, account: Constants.googleAccountIDAccount)
    }
}
