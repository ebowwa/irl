//
//  DeviceUUID.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation
import Security

struct DeviceUUID {
    static let key = "com.caringmind.deviceUUID"

    static func getUUID() -> String {
        if let uuid = getFromKeychain() {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            saveToKeychain(uuid: newUUID)
            return newUUID
        }
    }

    private static func saveToKeychain(uuid: String) {
        if let data = uuid.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            // Delete any existing item before adding to prevent duplicates
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Failed to save UUID to Keychain with status: \(status)")
            }
        }
    }

    private static func getFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr, let data = dataTypeRef as? Data, let uuid = String(data: data, encoding: .utf8) {
            return uuid
        }
        return nil
    }
}
//
//  RegistrationStatus.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation

struct RegistrationStatus {
    private static let registrationKey = "isDeviceRegistered"

    static func isDeviceRegistered() -> Bool {
        let status = UserDefaults.standard.bool(forKey: registrationKey)
        print("RegistrationStatus.isDeviceRegistered: \(status)")
        return status
    }

    static func setDeviceRegistered(_ registered: Bool) {
        UserDefaults.standard.set(registered, forKey: registrationKey)
        print("RegistrationStatus.setDeviceRegistered: \(registered)")
    }
}

