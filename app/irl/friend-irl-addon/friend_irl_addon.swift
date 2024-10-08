//
//  friend_irl_addon.swift
//  friend-irl-addon
//
//  Created by Elijah Arbee on 10/8/24.
//

import DeviceDiscoveryExtension

@main
class friend_irl_addon: DDDiscoveryExtension {
    
    /// A DeviceLocator that searches for devices on the network.
    private var networkDeviceLocator: DeviceLocator
    
    /// A DeviceLocator that searches for devices via Bluetooth.
    private var bluetoothDeviceLocator: DeviceLocator
    
    required init() {
        
        // Create DevliceLocators to look for network and Bluetooth devices.
        
        networkDeviceLocator = NetworkDeviceLocator()
        bluetoothDeviceLocator = BluetoothDeviceLocator()
    }
    
    /// Start searching for devices.
    func startDiscovery(session: DDDiscoverySession) {
        
        // Set up an event handler so the device locators can inform the session about devices.
        
        let eventHandler: DDEventHandler = { event in
            session.report(event)
        }
        
        networkDeviceLocator.eventHandler = eventHandler
        bluetoothDeviceLocator.eventHandler = eventHandler
        
        // Start scanning for devices.
        
        networkDeviceLocator.startScanning()
        bluetoothDeviceLocator.startScanning()
    }
    
    /// Stop searching for devices.
    func stopDiscovery(session: DDDiscoverySession) {
        // Stop scanning for devices.
        
        networkDeviceLocator.stopScanning()
        bluetoothDeviceLocator.stopScanning()
        
        // Ensure no more events are reported.
        
        networkDeviceLocator.eventHandler = nil
        bluetoothDeviceLocator.eventHandler = nil
    }
}

/// A DeviceLocator knows how to scan for devices and encapsulates the details about how it does so.
public protocol DeviceLocator {
    
    /// Start scanning for devices.
    func startScanning()
    
    /// Stop scanning for devices.
    func stopScanning()
    
    /// When a device changes state, the DeviceLocator will invoke this handler. The extension can then pass the given event back to its session.
    var eventHandler: DDEventHandler? { get set }
}
