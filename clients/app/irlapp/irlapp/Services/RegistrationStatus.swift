//
//  RegistrationStatus.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/19/24.
//


//
//  RegistrationStatus.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation

struct RegistrationStatus {
    private static let registrationKey = "isDeviceRegistered"

    /// Checks the local state reflecting the relationship with the server.
    static func isDeviceRegistered() -> Bool {
        let status = UserDefaults.standard.bool(forKey: registrationKey)
        print("RegistrationStatus.isDeviceRegistered: \(status)")
        return status
    }

    /// Updates the local state reflecting the relationship with the server.
    /// - Parameter registered: The current registration state with the server.
    static func setDeviceRegistered(_ registered: Bool) {
        UserDefaults.standard.set(registered, forKey: registrationKey)
        print("RegistrationStatus.setDeviceRegistered: \(registered)")
    }
}
