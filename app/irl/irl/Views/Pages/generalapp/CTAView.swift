//
//  CTAView.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

struct CTAView: View {
    var body: some View {
        VStack {
            Text("Let's start working more efficiently today!")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding()
            
            Text("Meet the people behind our magical product")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}
