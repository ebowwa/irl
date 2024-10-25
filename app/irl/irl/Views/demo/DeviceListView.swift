//
//  DeviceListView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/10/24.
//


import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var deviceManager: DeviceManager

    var body: some View {
        List {
            ForEach(deviceManager.connectedDevices, id: \.identifier) { device in
                HStack {
                    Text(device.name)
                        .font(.headline)
                    Spacer()
                    if device.isRecording {
                        Text("Recording")
                            .foregroundColor(.red)
                    } else if device.isConnected {
                        Text("Connected")
                            .foregroundColor(.blue)
                    } else {
                        Text("Disconnected")
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    deviceManager.startRecording(on: device)
                }
            }
            .onDelete(perform: deleteDevices)
        }
        .navigationTitle("Connected Devices")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addDevice) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func addDevice() {
        let newDevice = AudioDevice(name: "AirPods Pro") // Example device
        deviceManager.addDevice(newDevice)
    }

    private func deleteDevices(at offsets: IndexSet) {
        offsets.map { deviceManager.connectedDevices[$0] }.forEach { device in
            deviceManager.removeDevice(device)
        }
    }
}
