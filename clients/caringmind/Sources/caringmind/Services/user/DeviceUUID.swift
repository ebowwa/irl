//
//  DeviceUUID.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/12/24.
//

import Foundation

struct DeviceUUID {
    static func getUUID() -> String {
        if let data = KeychainHelper.standard.read(
            service: Constants.deviceUUIDService,
            account: Constants.deviceUUIDAccount
        ), let uuid = String(data: data, encoding: .utf8) {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            if let data = newUUID.data(using: .utf8) {
                KeychainHelper.standard.save(
                    data,
                    service: Constants.deviceUUIDService,
                    account: Constants.deviceUUIDAccount
                )
            }
            return newUUID
        }
    }
}
