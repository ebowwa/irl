//
//  SettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: GlobalState
    @AppStorage("isPushNotificationsEnabled") private var isPushNotificationsEnabled = false
    @AppStorage("isEmailNotificationsEnabled") private var isEmailNotificationsEnabled = false
    @StateObject private var serverHealthManager = ServerHealthManager()
    @State private var isAdvancedExpanded = false
    @State private var isSelfHostExpanded = false
    @State private var newApiKeyName = ""
    @State private var newApiKeyValue = ""
    @State private var customAPIKeys: [String: String] = [:]
    
    // Binding for baseDomain
    @State private var baseDomain = Constants.baseDomain
    
    // State properties for API keys
    @State private var openAIKey = Constants.APIKeys.openAI
    @State private var humeAIKey = Constants.APIKeys.humeAI
    @State private var anthropicAIKey = Constants.APIKeys.anthropicAI
    @State private var gcpKey = Constants.APIKeys.gcp
    @State private var falAPIKey = Constants.APIKeys.falAPI
    @State private var deepgramKey = Constants.APIKeys.deepgram

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

            Section(header: Text("Advanced")) {
                DisclosureGroup("Developer", isExpanded: $isAdvancedExpanded) {
                    NavigationLink(destination: ServerHealthSettingsView(serverHealthManager: serverHealthManager)) {
                        Text("Server Health Settings")
                    }
                    
                    DisclosureGroup("Backend Configuration", isExpanded: $isSelfHostExpanded) {
                        TextField("Base Domain", text: $baseDomain)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: baseDomain) { newValue in
                                Constants.baseDomain = newValue
                            }
                        
                        Group {
                            APIKeyField(title: "OpenAI", key: $openAIKey)
                                .onChange(of: openAIKey) { Constants.APIKeys.openAI = $0 }
                            APIKeyField(title: "Hume AI", key: $humeAIKey)
                                .onChange(of: humeAIKey) { Constants.APIKeys.humeAI = $0 }
                            APIKeyField(title: "Anthropic AI", key: $anthropicAIKey)
                                .onChange(of: anthropicAIKey) { Constants.APIKeys.anthropicAI = $0 }
                            APIKeyField(title: "GCP", key: $gcpKey)
                                .onChange(of: gcpKey) { Constants.APIKeys.gcp = $0 }
                            APIKeyField(title: "FAL API", key: $falAPIKey)
                                .onChange(of: falAPIKey) { Constants.APIKeys.falAPI = $0 }
                            APIKeyField(title: "Deepgram", key: $deepgramKey)
                                .onChange(of: deepgramKey) { Constants.APIKeys.deepgram = $0 }
                        }
                        
                        ForEach(customAPIKeys.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            APIKeyField(title: key, key: Binding(
                                get: { self.customAPIKeys[key] ?? "" },
                                set: { self.customAPIKeys[key] = $0 }
                            ))
                        }
                        
                        HStack {
                            TextField("New API Name", text: $newApiKeyName)
                            SecureField("New API Key", text: $newApiKeyValue)
                            Button(action: {
                                if !newApiKeyName.isEmpty {
                                    customAPIKeys[newApiKeyName] = newApiKeyValue
                                    newApiKeyName = ""
                                    newApiKeyValue = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
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

struct APIKeyField: View {
    let title: String
    @Binding var key: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            SecureField("API Key", text: $key)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ServerHealthSettingsView: View {
    @ObservedObject var serverHealthManager: ServerHealthManager
    @Environment(\.presentationMode) var presentationMode

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
                    if serverHealthManager.isConnected {
                        serverHealthManager.disconnect()
                    } else {
                        serverHealthManager.connect()
                    }
                }) {
                    Text(serverHealthManager.isConnected ? "Disconnect" : "Connect")
                }

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
        .onDisappear {
            if serverHealthManager.isConnected {
                serverHealthManager.disconnect()
            }
        }
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

/** TODO:
- correct state management
- establish privacy policy
- add ble button: connect, check, check battery, test ble device
**/
