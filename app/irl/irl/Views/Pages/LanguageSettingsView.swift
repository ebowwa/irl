//
//  LanguageSettingsView.swift
//  irl
//  TODO: automatically have the auto detect langauge toggled on, have it use the user permissions
// TODO: feature allow users to multiselect languages with information showing which services/models are supported for the specific langauge
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: AppLanguage
    @StateObject private var permissionManager = PermissionManager()
    @State private var isAutoDetectEnabled: Bool = false
    @State private var searchText: String = ""
    @State private var showLanguageInfo: Bool = false
    @State private var showPermissionInfo: Bool = false

    private let languageManager = LanguageManager.shared

    var body: some View {
        Form {
            Section(header: Text("Language Selection")) {
                Toggle("Auto Detect Language", isOn: $isAutoDetectEnabled)
                    .onChange(of: isAutoDetectEnabled) { newValue in
                        if newValue {
                            selectedLanguage = languageManager.language(forCode: "auto") ?? selectedLanguage
                            permissionManager.checkAndRequestPermissions()
                        } else {
                            selectedLanguage = languageManager.language(forCode: "en") ?? selectedLanguage
                        }
                    }
                    .disabled(!permissionManager.isMicrophoneAuthorized || !permissionManager.isSpeechRecognitionAuthorized)

                if !isAutoDetectEnabled {
                    TextField("Search Languages", text: $searchText)
                    
                    Picker("Select Language", selection: $selectedLanguage) {
                        ForEach(filteredLanguages, id: \.code) { language in
                            Text(language.name)
                                .tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            Section(header: HStack {
                Text("Language Information")
                Spacer()
                Button(action: {
                    showLanguageInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
            }) {
                if showLanguageInfo {
                    Text("Selected Language: \(selectedLanguage.name)")
                    Text("Language Code: \(selectedLanguage.code)")
                    Text("Whisper Supported: \(selectedLanguage.isWhisperSupported ? "Yes" : "No")")
                    Text("Claude Supported: \(selectedLanguage.isClaudeSupported ? "Yes" : "No")")
                }
            }

            Section(header: HStack {
                Text("Permissions")
                Spacer()
                Button(action: {
                    showPermissionInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
            }) {
                if showPermissionInfo {
                    Text("Microphone: \(permissionManager.isMicrophoneAuthorized ? "Authorized" : "Not Authorized")")
                    Text("Speech Recognition: \(permissionManager.isSpeechRecognitionAuthorized ? "Authorized" : "Not Authorized")")
                    
                    if !permissionManager.isMicrophoneAuthorized || !permissionManager.isSpeechRecognitionAuthorized {
                        Button("Request Permissions") {
                            permissionManager.checkAndRequestPermissions()
                        }
                    }
                }
            }
        }
        .onAppear {
            permissionManager.checkAndRequestPermissions()
        }
    }
    
    private var filteredLanguages: [AppLanguage] {
        let languages = languageManager.getAllLanguages().filter { $0.code != "auto" && $0.code != "unknown" }
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct LanguageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSettingsView(selectedLanguage: .constant(AppLanguage(code: "en", name: "English", service: ["falwhisperSep2024", "anthropic-claude-3"])))
    }
}
