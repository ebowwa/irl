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
                    serverHealthManager.disconnect()
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

// MARK: - TODO: Implement WebSocket Disconnection
// To address the TODO for disconnecting from the WebSocket when leaving the page:
// 1. Add a disconnect() method to the ServerHealthManager class.
// 2. Call this method when the view disappears or when the app enters the background.
// 3. Update the "Disconnect" button to call this new method.

// Example implementation:
//
// extension ServerHealthWidget {
//     func disconnectWebSocket() {
//         if serverHealthManager.isConnected {
//             serverHealthManager.disconnect()
//         }
//     }
// }
//
// // In the parent view or app delegate:
// .onDisappear {
//     serverHealthWidget.disconnectWebSocket()
// }
//
// // For app lifecycle events:
// NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
//     serverHealthWidget.disconnectWebSocket()
// }

// MARK: - Code Explanation
// This SwiftUI view, ServerHealthWidget, displays and manages server health information:
//
// 1. It uses an @ObservedObject serverHealthManager to track and update server status.
// 2. The view shows the connection status (Connected/Disconnected) with color coding.
// 3. It displays the timestamp of the last received pong message.
// 4. A "Send Ping" button allows manual ping requests when connected.
// 5. A "Connect/Disconnect" button toggles the connection state.
// 6. The widget has a styled container with padding, background, corner radius, and shadow.
//
// The TODO reminder highlights the need to implement proper WebSocket disconnection
// when the user navigates away from the page or when the app enters the background.
// This is crucial for maintaining clean connections and preventing resource leaks.
