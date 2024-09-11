//
//  SaveConfigurationView.swift
//  irl
// TODO: handle zero changes from the default as not needing a save so dont ask nor do
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI

struct SaveConfigurationView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @Binding var configTitle: String
    @Binding var configDescription: String
    let onSave: (Bool) -> Void // Bool parameter indicates whether it's a draft
    let onDiscard: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration Details")) {
                    TextField("Title", text: $configTitle)
                    TextEditor(text: $configDescription)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Save Configuration")
            .navigationBarItems(
                leading: Button("Save as Draft") {
                    onSave(true)
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Discard") {
                        showingDiscardAlert = true
                    }
                    Button("Save") {
                        onSave(false)
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
                    onDiscard()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
