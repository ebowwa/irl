//
//  FAQSection.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

struct FAQSection: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Frequently asked questions")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            FAQView(question: "How does this work?")
            FAQView(question: "What are the benefits?")
            FAQView(question: "Is it difficult to use?")
            FAQView(question: "Can I have custom pricing?")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}

struct FAQView: View {
    var question: String
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Text(question)
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Text("Answer goes here...")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
