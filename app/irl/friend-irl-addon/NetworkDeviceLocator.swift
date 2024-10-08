//
//  NetworkDeviceLocator.swift
//  friend-irl-addon
//
//  Created by Elijah Arbee on 10/8/24.
//

import DeviceDiscoveryExtension
import Network
import UniformTypeIdentifiers

/// A DeviceLocator that uses a network browser to search for devices via Bonjour.
class NetworkDeviceLocator: DeviceLocator {
    
    /// The network browser used to scan for devices.
    private var browser: NWBrowser
    
    /// The devices known to this locator.
    private var knownDevices: [DDDevice] = []
    
    init() {
        
        // An example Bonjour service type for the device for which to scan.
        // This must match a value contained within the NSBonjourServices array in the extension's Info.plist.
        let exampleServiceType = "_example._tcp"
        
        // Create a network browser to search for devices.
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: exampleServiceType, domain: nil), using: parameters)
    }
    
    /// The event handler that passes events back to the session.
    var eventHandler: DDEventHandler?
    
    /// Start scanning for devices using the network browser.
    func startScanning() {
        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    self.didDiscover(result)
                }
            }
        }
        
        knownDevices = []
        browser.start(queue: .main)
    }
    
    /// Stop scanning for devices using the network browser.
    func stopScanning() {
        browser.cancel()
        
        browser.browseResultsChangedHandler = nil
        
        if let eventHandler = eventHandler {
            for device in knownDevices {
                let event = DDDeviceEvent(eventType: .deviceLost, device: device)
                eventHandler(event)
            }
        }
        knownDevices.removeAll()
    }
    
    /// Inform the session of the device state represented by the result.
    func didDiscover(_ result: NWBrowser.Result) {
        
        // If no event handler is set, don't report anything.
        
        guard let eventHandler = eventHandler else {
            return
        }
        
        // An example device identifier and name for the discovered device.
        // It's important that this come from or be associated with the device itself.
        let exampleDeviceUUID = UUID()
        let exampleDeviceIdentifier = exampleDeviceUUID.uuidString
        let exampleDeviceName = result.endpoint.debugDescription
        
        // An example protocol for the discovered device.
        // This must match the type declared in the extension's Info.plist.
        guard let exampleDeviceProtocol = UTType("com.example.example-protocol") else {
            fatalError("Misconfiguration: UTType for protocol not defined.")
        }
        
        // Create a DDDevice instance representing the device.
        let device = DDDevice(displayName: exampleDeviceName, category: .tv, protocolType: exampleDeviceProtocol, identifier: exampleDeviceIdentifier)
        device.networkEndpoint = result.endpoint
        
        knownDevices.append(device)
        
        // Pass it to the event handler.
        
        let event = DDDeviceEvent(eventType: .deviceFound, device: device)
        eventHandler(event)
    }
}
