//
//  AIAlignmentView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI

struct AIAlignmentView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    
    var body: some View {
        Form {
            Section(header: Text("AI Alignment Configuration")) {
                Text("Customize your AI assistant by providing details about its personality, skills, learning objectives, and intended behaviors.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            
            Section(header: Text("Personality")) {
                TextEditor(text: $viewModel.personality)
                    .frame(height: 100)
            }
            
            Section(header: Text("Skills")) {
                TextEditor(text: $viewModel.skills)
                    .frame(height: 100)
            }
            
            Section(header: Text("Learning Objectives")) {
                TextEditor(text: $viewModel.learningObjectives)
                    .frame(height: 100)
            }
            
            Section(header: Text("Intended Behaviors")) {
                TextEditor(text: $viewModel.intendedBehaviors)
                    .frame(height: 100)
            }
            
            Section(header: Text("Specific Needs")) {
                TextEditor(text: $viewModel.specificNeeds)
                    .frame(height: 100)
            }
        }
        .navigationTitle("AI Alignment")
    }
}
