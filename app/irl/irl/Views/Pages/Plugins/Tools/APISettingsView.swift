//
//  APISettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//

import SwiftUI

struct APISettingsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Third-party API Endpoint")) {
                    TextField("Enter API endpoint", text: $viewModel.apiEndpoint)
                }
                
                Section(header: Text("JSON Schema")) {
                    TextEditor(text: $viewModel.jsonSchema)
                        .frame(height: 200)
                }
            }
            .navigationTitle("API Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
