//
//  SettingsViewIndex.swift
//  irl
//  Created by Elijah Arbee on 9/9/24.
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
    @State private var openAIKey = ConstantAPIKeys.openAI
    @State private var humeAIKey = ConstantAPIKeys.humeAI
    @State private var anthropicAIKey = ConstantAPIKeys.anthropicAI
    @State private var gcpKey = ConstantAPIKeys.gcp
    @State private var falAPIKey = ConstantAPIKeys.falAPI
    @State private var deepgramKey = ConstantAPIKeys.deepgram

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                AppearanceSettingsView()
            }
/**
            Section(header: Text("Language")) {
                NavigationLink(destination: LanguageSettingsView(selectedLanguage: $appState.selectedLanguage)) {
                    HStack {
                        Text("Language")
                        Spacer()
                        Text(appState.selectedLanguage.name)
                            .foregroundColor(.gray)
                    }
                }
            }
 */
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
                    NavigationLink(destination: ServerHealthWidget(serverHealthManager: serverHealthManager)) {
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
                                .onChange(of: openAIKey) { ConstantAPIKeys.openAI = $0 }
                            APIKeyField(title: "Hume AI", key: $humeAIKey)
                                .onChange(of: humeAIKey) { ConstantAPIKeys.humeAI = $0 }
                            APIKeyField(title: "Anthropic AI", key: $anthropicAIKey)
                                .onChange(of: anthropicAIKey) { ConstantAPIKeys.anthropicAI = $0 }
                            APIKeyField(title: "GCP", key: $gcpKey)
                                .onChange(of: gcpKey) { ConstantAPIKeys.gcp = $0 }
                            APIKeyField(title: "FAL API", key: $falAPIKey)
                                .onChange(of: falAPIKey) { ConstantAPIKeys.falAPI = $0 }
                            APIKeyField(title: "Deepgram", key: $deepgramKey)
                                .onChange(of: deepgramKey) { ConstantAPIKeys.deepgram = $0 }
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
                HStack {
                    Text("Created by")
                    Spacer()
                    Text("ebowwa")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            if let url = URL(string: "https://ebowwa.xyz") {
                                UIApplication.shared.open(url)
                            }
                        }
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
