//
//  HomeView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/2/24.
//

import SwiftUI

struct HomeView: View {
    // Instantiate PersistentAudioManager as a StateObject to observe its published properties
    @StateObject private var audioManager = PersistentAudioManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Title
                Text("Persistent Audio Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Spacer()
                
                // Speech Detection Indicator
                HStack {
                    Text("Speech State:")
                        .font(.headline)
                    
                    Circle()
                        .fill(speechStateColor)
                        .frame(width: 20, height: 20)
                        .animation(.easeInOut(duration: 0.5), value: audioManager.audioState)
                }
                
                // Start/Stop Recording Button
                Button(action: {
                    if audioManager.isRecording {
                        audioManager.stopContinuousProcessing()
                    } else {
                        audioManager.startContinuousProcessing()
                    }
                }) {
                    HStack {
                        Image(systemName: audioManager.isRecording ? "stop.circle" : "mic.circle")
                            .font(.title)
                        Text(audioManager.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(audioManager.isRecording ? Color.red : Color.blue)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Status Messages or Additional Information (Optional)
                VStack(alignment: .leading, spacing: 10) {
                    if audioManager.isRecording {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Recording in progress...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Tap the button above to start recording audio.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
            .alert(isPresented: $audioManager.showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(audioManager.errorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(
                // Optional: Background Gradient or Image
                LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            )
        }
    }
    
    // MARK: - Computed Property for Speech State Color
    
    private var speechStateColor: Color {
        switch audioManager.audioState {
        case .idle:
            return Color.red
        case .listening:
            return Color.yellow
        case .detecting:
            return Color.green
        case .error(_):
            return Color.red
        }
    }
}

