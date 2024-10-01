//
//  ToolsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI

struct ToolsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    @State private var showingAPISettings = false
    
    var body: some View {
        Form {
            Section(header: Text("AI Alignment")) {
                Toggle("Use AI Alignment", isOn: $viewModel.useAIAlignment)
                if viewModel.useAIAlignment {
                    NavigationLink(destination: AIAlignmentView(viewModel: viewModel)) {
                        Text("Configure AI Alignment")
                    }
                }
            }
            
            Section(header: Text("Generation Capabilities")) {
                Toggle("Image Generation", isOn: $viewModel.imageGenerationEnabled)
                
                HStack {
                    Text("Speech Generation")
                    Spacer()
                    Image(systemName: "speaker.slash")
                        .foregroundColor(.gray)
                }
                .opacity(0.5)
                
                HStack {
                    Text("Video Generation")
                    Spacer()
                    Image(systemName: "video.slash")
                        .foregroundColor(.gray)
                }
                .opacity(0.5)
            }
            
            Section {
                Button("Configure API Endpoint") {
                    showingAPISettings = true
                }
            }
            
            Section {
                Link("Suggest a Feature", destination: URL(string: "https://forms.gle/yourGoogleFormURL")!)
            }
            
            Section {
                Link("Report a Bug", destination: URL(string: "https://forms.gle/yourGoogleFormURL")!)
            }
        }
        .sheet(isPresented: $showingAPISettings) {
            APISettingsView(viewModel: viewModel)
        }
    }
}
