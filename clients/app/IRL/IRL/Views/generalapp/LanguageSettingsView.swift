//
//  LanguageSettingsView.swift
//  irl
//  TODO: automatically have the auto detect language toggled on, have it use the user permissions
//  TODO: feature allow users to multiselect languages with information showing which services/models are supported for the specific language
//  Created by Elijah Arbee on 8/29/24.
//

import SwiftUI

struct LanguageSettingsView: View {
    @Binding var selectedLanguages: [AppLanguage] // Updated to support multiple languages
    @State private var isAutoDetectEnabled: Bool = false
    @State private var searchText: String = ""
    @State private var showLanguageInfo: Bool = false
    @State private var showPermissionRequest: Bool = false
    
    private let languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                // Language Selection Section
                Section(header: Text("Language Selection")) {
                    Toggle("Auto Detect Language", isOn: $isAutoDetectEnabled)
                        .onChange(of: isAutoDetectEnabled) { newValue in
                            if newValue {
                                selectedLanguages = [languageManager.language(forCode: "auto") ?? selectedLanguages.first ?? languageManager.getDefaultLanguage() ?? AppLanguage(code: "en", name: "English", service: nil)]
                            }
                        }
                    
                    // Only show language picker if Auto Detect is disabled
                    if !isAutoDetectEnabled {
                        TextField("Search Languages", text: $searchText)
                        
                        // Multi-Select Picker for Languages
                        List {
                            ForEach(filteredLanguages, id: \.code) { language in
                                MultipleSelectionRow(language: language, isSelected: selectedLanguages.contains(language)) {
                                    if selectedLanguages.contains(language) {
                                        selectedLanguages.removeAll { $0 == language }
                                    } else {
                                        selectedLanguages.append(language)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Language Information Section
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
                        ForEach(selectedLanguages, id: \.code) { language in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Selected Language: \(language.name)")
                                Text("Language Code: \(language.code)")
                                Text("Whisper Supported: \(language.isWhisperSupported ? "Yes" : "No")")
                                Text("Claude Supported: \(language.isClaudeSupported ? "Yes" : "No")")
                            }
                        }
                    }
                }
                
                // Permissions Section
                Section(header: HStack {
                    Text("Permissions")
                    Spacer()
                    Button(action: {
                        showPermissionRequest.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                }) {
                    NavigationLink(destination: PermissionsRequestView(step: .constant(0)), isActive: $showPermissionRequest) {
                        Text("Manage Permissions")
                    }
                }
            }
            .navigationTitle("Language Settings")
        }
    }
    
    // Filtered languages based on search text
    private var filteredLanguages: [AppLanguage] {
        let languages = languageManager.getAllLanguages().filter { $0.code != "auto" && $0.code != "unknown" }
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // Row for multiple selection
    struct MultipleSelectionRow: View {
        let language: AppLanguage
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            HStack {
                Text(language.name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle()) // Makes the whole row tappable
            .onTapGesture {
                action()
            }
        }
    }
    
    struct LanguageSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            LanguageSettingsView(selectedLanguages: .constant([AppLanguage(code: "en", name: "English", service: ["falwhisperSep2024", "anthropic-claude-3"])]))
        }
    }
}
