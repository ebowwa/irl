//
//  PrivacySettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct PrivacySettingsView: View {
    @State private var isLocationEnabled = false
    @State private var isDataSharingEnabled = false
    @State private var isMicrophoneEnabled = false
    @State private var isCameraEnabled = false
    @State private var isBluetoothEnabled = false

    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                Toggle("Enable Location", isOn: $isLocationEnabled)
                Toggle("Enable Microphone", isOn: $isMicrophoneEnabled)
                Toggle("Enable Camera", isOn: $isCameraEnabled)
                Toggle("Enable Bluetooth", isOn: $isBluetoothEnabled)
            }

            Section(header: Text("Data Sharing")) {
                Toggle("Allow Data Sharing", isOn: $isDataSharingEnabled)
            }

            Section(header: Text("Privacy Policy")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("View Privacy Policy")
                }
            }

            Section(header: Text("Account")) {
                Button("Delete Account") {
                    // Implement account deletion logic
                }
                .foregroundColor(.red)
            }
        }
        .navigationBarTitle("Privacy Settings", displayMode: .inline)
    }
}

struct PrivacyPolicyView: View {
    @State private var privacyPolicy: PrivacyPolicy?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let policy = privacyPolicy {
                    Text(policy.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(policy.lastUpdated)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(policy.sections, id: \.title) { section in
                        Text(section.title)
                            .font(.headline)
                        
                        Text(section.content)
                            .font(.body)
                    }
                } else {
                    Text("Loading Privacy Policy...")
                }
            }
            .padding()
        }
        .navigationBarTitle("Privacy Policy", displayMode: .inline)
        .onAppear(perform: loadPrivacyPolicy)
    }
    
    private func loadPrivacyPolicy() {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "json") else {
            print("Privacy policy JSON file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            privacyPolicy = try decoder.decode(PrivacyPolicy.self, from: data)
        } catch {
            print("Error decoding privacy policy: \(error)")
        }
    }
}

struct PrivacyPolicy: Codable {
    let title: String
    let lastUpdated: String
    let sections: [PolicySection]
}

struct PolicySection: Codable {
    let title: String
    let content: String
}

#if DEBUG
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsView()
        }
    }
}
#endif
