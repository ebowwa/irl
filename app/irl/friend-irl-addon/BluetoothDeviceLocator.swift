//
//  BluetoothDeviceLocator.swift
//  friend-irl-addon
//
//  Created by Elijah Arbee on 10/8/24.
//

import DeviceDiscoveryExtension
import CoreBluetooth
import UniformTypeIdentifiers

/// A DeviceLocator that searches for devices using CoreBluetooth.
class BluetoothDeviceLocator: NSObject, DeviceLocator, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /// The central manager for Bluetooth communications.
    private var centralManager: CBCentralManager
    private var friendPeripheral: CBPeripheral? // The connected "Friend" peripheral
    
    override init() {
        // Create a central Bluetooth manager to search for devices.
        centralManager = CBCentralManager(delegate: nil, queue: nil, options: [:])
        super.init()
        centralManager.delegate = self
    }
    
    /// The event handler that passes events back to the session.
    var eventHandler: DDEventHandler?
    
    /// The devices known to this locator.
    private var knownDevices: [DDDevice] = []
    
    /// Start scanning for devices using Bluetooth.
    func startScanning() {
        // Start scanning for peripherals with the name "Friend" or associated services.
        let friendServiceUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")  // Audio service UUID
        
        centralManager.scanForPeripherals(withServices: [friendServiceUUID])
    }
    
    /// Stop scanning for devices using Bluetooth.
    func stopScanning() {
        // Stop the central manager from scanning.
        centralManager.stopScan()
    }
    
    /// Handle device discovery.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // If no event handler is set, don't report anything.
        guard let eventHandler = eventHandler else {
            return
        }
        
        // Check if the device name is "Friend"
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String, deviceName == "Friend" {
            friendPeripheral = peripheral
            friendPeripheral?.delegate = self
            centralManager.stopScan()  // Stop scanning once the device is found
            centralManager.connect(peripheral, options: nil)  // Connect to the Friend device
        }
        
        // Example device data for event handling
        let exampleDeviceUUID = UUID()
        let exampleDeviceIdentifier = exampleDeviceUUID.uuidString
        let exampleDeviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        guard let exampleDeviceProtocol = UTType("com.example.example-protocol") else {
            fatalError("Misconfiguration: UTType for protocol not defined.")
        }
        
        let device = DDDevice(displayName: exampleDeviceName, category: .hifiSpeaker, protocolType: exampleDeviceProtocol, identifier: exampleDeviceIdentifier)
        device.bluetoothIdentifier = exampleDeviceUUID
        knownDevices.append(device)
        
        // Pass it to the event handler.
        let event = DDDeviceEvent(eventType: .deviceFound, device: device)
        eventHandler(event)
    }
    
    /// Handle connection to the Friend device.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to Friend device.")
        peripheral.discoverServices(nil)  // Discover all services on the peripheral
    }
    
    /// Handle service discovery.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                switch service.uuid {
                case CBUUID(string: "180F"):  // Battery Service
                    peripheral.discoverCharacteristics(nil, for: service)
                case CBUUID(string: "180A"):  // Device Information Service
                    peripheral.discoverCharacteristics(nil, for: service)
                case CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214"):  // Audio Service
                    peripheral.discoverCharacteristics(nil, for: service)
                default:
                    break
                }
            }
        }
    }
    
    /// Handle characteristic discovery.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CBUUID(string: "2A19"):  // Battery Level characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                case CBUUID(string: "2A29"), CBUUID(string: "2A24"), CBUUID(string: "2A27"), CBUUID(string: "2A26"):  // Device Info characteristics
                    peripheral.readValue(for: characteristic)
                case CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214"):  // Audio Data characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                case CBUUID(string: "19B10002-E8F2-537E-4F6C-D104768A1214"):  // Codec Type characteristic
                    peripheral.readValue(for: characteristic)
                default:
                    break
                }
            }
        }
    }
    
    /// Handle updated value for characteristic (e.g., receiving audio data, battery level).
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            switch characteristic.uuid {
            case CBUUID(string: "2A19"):  // Battery Level
                let batteryLevel = data[0]  // Read battery level as an integer percentage
                print("Battery Level: \(batteryLevel)%")
                
            case CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214"):  // Audio Data
                // Handle audio streaming data
                print("Received audio data.")
                // You will need to implement audio decoding here based on codec type
                
            case CBUUID(string: "19B10002-E8F2-537E-4F6C-D104768A1214"):  // Codec Type
                let codecType = data[0]  // Determine codec type (PCM, Opus, etc.)
                print("Codec Type: \(codecType)")
                
            default:
                break
            }
        }
    }
    
    /// Handle state updates for the central manager itself.
    /// This required protocol method can be used to detect when Bluetooth status changes, by checking the central manager's state property.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state changes, for example by informing the eventHandler that the devices that were previously discovered are no longer available.
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            if let eventHandler = eventHandler {
                for device in knownDevices {
                    let event = DDDeviceEvent(eventType: .deviceLost, device: device)
                    eventHandler(event)
                }
            }
            knownDevices.removeAll()
        case .poweredOn:
            knownDevices = []
        @unknown default:
            break
        }
    }
}
