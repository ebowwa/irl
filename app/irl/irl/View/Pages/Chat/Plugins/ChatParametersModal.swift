//
//  ChatParametersModal.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI

struct ChatParametersModal: View {
    @StateObject private var viewModel: ChatParametersViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showingSaveDialog = false
    @State private var configTitle = ""
    @State private var configDescription = ""
    
    init(claudeViewModel: ClaudeViewModel) {
        _viewModel = StateObject(wrappedValue: ChatParametersViewModel(claudeViewModel: claudeViewModel))
    }
    
    var body: some View {
        NavigationView {
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
                showingSaveDialog = true
            })
        }
        .sheet(isPresented: $showingSaveDialog) {
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

            private func saveConfiguration(isDraft: Bool) {
        
                let config = Configuration(
                    title: configTitle,
                    description: configDescription,
                    parameters: viewModel,
                    isDraft: isDraft
                )
                LocalStorage.saveConfiguration(config)
                
                if !isDraft {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
