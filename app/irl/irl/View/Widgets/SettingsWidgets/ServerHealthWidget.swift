//
//  ServerHealthWidget.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import SwiftUI

struct ServerHealthWidget: View {
    @ObservedObject var serverHealthManager: ServerHealthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Server Health")
                .font(.headline)
            
            HStack {
                Text("Status:")
                Text(serverHealthManager.isConnected ? "Connected" : "Disconnected")
                    .foregroundColor(serverHealthManager.isConnected ? .green : .red)
            }
            
            HStack {
                Text("Last Pong:")
                Text(serverHealthManager.lastPongReceived)
            }
            
            Button(action: {
                serverHealthManager.sendPing()
            }) {
                Text("Send Ping")
            }
            .disabled(!serverHealthManager.isConnected)
            
            Button(action: {
                if serverHealthManager.isConnected {
                    // Assuming there's no disconnect method, we'll just print for now
                    print("Disconnect action needed")
                } else {
                    serverHealthManager.connect()
                }
            }) {
                Text(serverHealthManager.isConnected ? "Disconnect" : "Connect")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ServerHealthWidget_Previews: PreviewProvider {
    static var previews: some View {
        ServerHealthWidget(serverHealthManager: ServerHealthManager())
    }
}
