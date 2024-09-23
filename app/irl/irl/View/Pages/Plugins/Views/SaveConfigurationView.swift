//
//  SaveConfigurationView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
//  This view presents a form for saving configuration details.
//  Users can enter a title and description, save the configuration as a draft, save normally, or discard changes.
//
// TODO:
// - Handle scenarios where no changes are made from the default configuration to avoid unnecessary save prompts.
// - Integrate SQL for persistent storage, enabling editing of existing configurations and adding more features.
//

import SwiftUI

struct SaveConfigurationView: View {
    // Observes the ChatParametersViewModel to reflect any changes in the UI.
    @ObservedObject var viewModel: ChatParametersViewModel
    
    // Bindings to capture user input for configuration title and description.
    @Binding var configTitle: String
    @Binding var configDescription: String
    
    // Callbacks for save and discard actions.
    let onSave: (Bool) -> Void // Bool indicates if the save is a draft.
    let onDiscard: () -> Void
    
    // Environment variable to manage the presentation mode of the view.
    @Environment(\.presentationMode) var presentationMode
    
    // State variable to control the display of the discard confirmation alert.
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Section for entering configuration details.
                Section(header: Text("Configuration Details")) {
                    TextField("Title", text: $configTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                    
                    TextEditor(text: $configDescription)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle("Save Configuration")
            .navigationBarItems(
                leading: Button("Save as Draft") {
                    onSave(true) // Save as draft.
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Discard") {
                        showingDiscardAlert = true // Show discard confirmation.
                    }
                    Button("Save") {
                        onSave(false) // Save normally.
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .alert(isPresented: $showingDiscardAlert) {
            Alert(
                title: Text("Discard Changes"),
                message: Text("Are you sure you want to discard your changes?"),
                primaryButton: .destructive(Text("Discard")) {
                    onDiscard() // Perform discard action.
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
