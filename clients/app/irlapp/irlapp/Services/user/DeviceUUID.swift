//
//  DeviceUUID.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation

struct DeviceUUID {
    static func getUUID() -> String {
        if let uuid = KeychainHelper.standard.read(service: "CaringMindService", account: "DeviceUUID") {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            KeychainHelper.standard.save(newUUID, service: "CaringMindService", account: "DeviceUUID")
            return newUUID
        }
    }
}
