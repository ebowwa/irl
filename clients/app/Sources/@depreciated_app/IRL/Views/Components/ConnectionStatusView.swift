//
//  ConnectionStatusView.swift
//  irl
//
//  Created by Elijah Arbee on 10/2/24.
//
import SwiftUI
import Foundation
// Connection status display view
struct ConnectionStatusView: View {
    @Binding var activeConnection: LiveView.ConnectionType?

    var body: some View {
        VStack {
            if let connection = activeConnection {
                switch connection {
                case .ble:
                    Text("🔗") // BLE connection emoji
                case .wifi:
                    Text("📶") // WiFi connection emoji
                case .other:
                    Text("🔌") // Other connection emoji
                }
            } else {
                Text("No connection")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}
