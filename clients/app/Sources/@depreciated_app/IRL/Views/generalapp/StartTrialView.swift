//
//  StartTrialView.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

struct StartTrialView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("The best way to showcase your project.")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Here you can put a short description about your project.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                Button(action: {
                    // Action for Try For Free
                }) {
                    Text("Try for free")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // Action for See How It Works
                }) {
                    Text("See how it works")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}
