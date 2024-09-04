//
//  SettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
/** TODO:
- correct state management
- establish privacy policy
- add ble button: connect, check, check battery, test ble device
**/
import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var appState: GlobalState
    @AppStorage("isPushNotificationsEnabled") private var isPushNotificationsEnabled = false
    @AppStorage("isEmailNotificationsEnabled") private var isEmailNotificationsEnabled = false
    @StateObject private var serverHealthManager = ServerHealthManager()

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                AppearanceSettingsView()
            }

            Section(header: Text("Language")) {
                Picker("Language", selection: $appState.selectedLanguage) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Text(language.rawValue.capitalized).tag(language)
                    }
                }
            }

            Section(header: Text("Notifications")) {
                Toggle("Push Notifications", isOn: $isPushNotificationsEnabled)
                Toggle("Email Notifications", isOn: $isEmailNotificationsEnabled)
            }

            Section(header: Text("Privacy")) {
                NavigationLink(destination: PrivacySettingsView()) {
                    Text("Privacy Settings")
                }
            }

            Section(header: Text("Server Health")) {
                NavigationLink(destination: ServerHealthSettingsView(serverHealthManager: serverHealthManager)) {
                    Text("Server Health Settings")
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.0.1")
                }
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct ServerHealthSettingsView: View {
    @ObservedObject var serverHealthManager: ServerHealthManager

    var body: some View {
        Form {
            Section(header: Text("WebSocket URL")) {
                TextField("Enter WebSocket URL", text: $serverHealthManager.webSocketURL)
            }

            Section(header: Text("Test Connection URL")) {
                TextField("Enter Test Connection URL", text: $serverHealthManager.testConnectionURL)
            }

            Section {
                Button(action: {
                    serverHealthManager.connect()
                }) {
                    Text(serverHealthManager.isConnected ? "Connected" : "Connect")
                }
                .disabled(serverHealthManager.isConnected)

                Button(action: {
                    serverHealthManager.sendPing()
                }) {
                    Text("Send Ping")
                }
                .disabled(!serverHealthManager.isConnected)

                Button(action: {
                    serverHealthManager.testConnection()
                }) {
                    Text("Test Connection")
                }
            }

            Section(header: Text("Status")) {
                Text("Last Pong Received: \(serverHealthManager.lastPongReceived)")
            }

            Section(header: Text("Log")) {
                ScrollView {
                    Text(serverHealthManager.log)
                }
                .frame(height: 200)
            }
        }
        .navigationTitle("Server Health Settings")
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(GlobalState())
        }
    }
}
#endif



/**
 
 LIKE PRIVACY SHOULD HAVE AI SECTION
 
 should also allow for customized maintabmenu items
 i.e.:
  - chat
  - transcript w/ timestamps, & speech prosody
  - advocate
  - coach/mentor
  - other's {build this :) custom plugins - to keep private or share with the community}
 */
