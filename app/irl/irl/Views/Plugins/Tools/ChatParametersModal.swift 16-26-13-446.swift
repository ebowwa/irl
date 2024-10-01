//
//  ChatParametersModal.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
//  This modal view allows users to configure chat parameters across different tabs.
//  Users can navigate between Developer, Tools, and Memory settings and choose to save or discard their configurations.
//

import SwiftUI

struct ChatParametersModal: View {
    // Observes the ChatParametersViewModel to reflect any changes in the UI.
    @ObservedObject var viewModel: ChatParametersViewModel
    
    // Environment variable to manage the presentation mode of the modal.
    @Environment(\.presentationMode) var presentationMode
    
    // State variables to manage the selected tab and the display of the save dialog.
    @State private var selectedTab = 0
    @State private var showingSaveDialog = false
    
    // State variables to capture user input for configuration title and description.
    @State private var configTitle = ""
    @State private var configDescription = ""
    
    // Initializes the view with a given view model.
    init(viewModel: ChatParametersViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            // TabView containing different settings sections.
            TabView(selection: $selectedTab) {
                AdvancedSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Developer", systemImage: "gearshape.2")
                    }
                    .tag(1)
                
                ToolsView(viewModel: viewModel)
                    .tabItem {
                        Label("Tools", systemImage: "network")
                    }
                    .tag(2)
                
                MemorySettingsView()
                    .tabItem {
                        Label("Memory", systemImage: "brain")
                    }
                    .tag(3)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                showingSaveDialog = true // Show the save configuration dialog.
            })
        }
        .sheet(isPresented: $showingSaveDialog) {
            // Presents the SaveConfigurationView as a sheet.
            SaveConfigurationView(
                viewModel: viewModel,
                configTitle: $configTitle,
                configDescription: $configDescription,
                onSave: { isDraft in
                    saveConfiguration(isDraft: isDraft)
                },
                onDiscard: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    /// Saves the current configuration based on user input.
    /// - Parameter isDraft: Indicates whether the configuration is a draft.
    private func saveConfiguration(isDraft: Bool) {
        let config = Configuration(
            title: configTitle,
            description: configDescription,
            parameters: viewModel,
            isDraft: isDraft
        )
        LocalStorage.saveConfiguration(config)
        
        // Dismiss the modal after saving, regardless of draft status.
        presentationMode.wrappedValue.dismiss()
    }
}
