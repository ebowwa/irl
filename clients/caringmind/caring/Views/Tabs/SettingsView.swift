import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    
    init() {
        // Initialize ViewModel with injected settings
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settings: AppSettings.shared))
    }
    
    var body: some View {
        NavigationView {
            List {
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Toggle("Notifications", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _ in
                            viewModel.updateSettings()
                        }
                    
                    Toggle("Dark Mode", isOn: $settings.darkModeEnabled)
                        .onChange(of: settings.darkModeEnabled) { _ in
                            viewModel.updateSettings()
                        }
                    
                    Toggle("Sound Effects", isOn: $settings.soundEnabled)
                        .onChange(of: settings.soundEnabled) { _ in
                            viewModel.updateSettings()
                        }
                }
                
                // Account Section
                Section(header: Text("Account")) {
                    Button(action: {
                        // Implement account settings
                    }) {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        // Implement privacy settings
                    }) {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    Button(action: {
                        // Implement help center
                    }) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        // Implement contact support
                    }) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }
                
                // Developer Options Section
                Section(header: Text("Developer Options")) {
                    Toggle("Developer Mode", isOn: $settings.devModeEnabled)
                        .onChange(of: settings.devModeEnabled) { _ in
                            viewModel.updateSettings()
                        }
                    
                    if settings.devModeEnabled {
                        Button(action: {
                            viewModel.showTutorial = true
                        }) {
                            Label("Open Tutorial", systemImage: "book.fill")
                        }
                        
                        NavigationLink(destination: Text("Debug Console")) {
                            Label("Debug Console", systemImage: "terminal.fill")
                        }
                        
                        Button(action: {
                            // Reset app state for testing
                        }) {
                            Label("Reset App State", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button(action: {
                            // Clear cache
                        }) {
                            Label("Clear Cache", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        viewModel.showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                viewModel.isPresented = false
                dismiss()
            })
            .sheet(isPresented: $viewModel.showTutorial) {
                TutorialView()
            }
            .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.signOut()
                            // isSignedIn = false // Removed this line as it's not defined in the updated code
                            viewModel.postSignOutNotification()
                            dismiss()
                        } catch {
                            print("Error signing out: \(error)")
                            // Optionally, present an error alert to the user
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .environment(\.colorScheme, settings.darkModeEnabled ? .dark : .light)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
