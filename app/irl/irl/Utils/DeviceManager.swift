//
//  DeviceManager.swift
//  IRL
//
//  Created by Elijah Arbee on 10/10/24.
//


import Foundation

class DeviceManager: ObservableObject {
    @Published private(set) var connectedDevices: [Device] = []

    // Singleton instance for global access.
    static let shared = DeviceManager()

    private init() {}

    // MARK: - Device Management
    
    /// Adds a new device to the manager and connects it.
    func addDevice(_ device: Device) {
        connectedDevices.append(device)
        device.connect()
    }

    /// Removes a device from the manager and disconnects it.
    func removeDevice(_ device: Device) {
        device.disconnect()
        if let index = connectedDevices.firstIndex(where: { $0.identifier == device.identifier }) {
            connectedDevices.remove(at: index)
        }
    }

    // MARK: - Recording Controls
    
    /// Starts recording on a specific device.
    func startRecording(on device: Device) {
        device.startRecording()
    }

    /// Stops recording on a specific device.
    func stopRecording(on device: Device) {
        device.stopRecording()
    }

    /// Starts recording on all connected devices.
    func startRecordingOnAllDevices() {
        for device in connectedDevices where device.isConnected {
            device.startRecording()
        }
    }

    /// Stops recording on all connected devices.
    func stopRecordingOnAllDevices() {
        for device in connectedDevices where device.isConnected {
            device.stopRecording()
        }
    }
}
