//
//  StoriesView.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

// View for the Stories Scroll View
struct StoriesView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(0..<9) { index in
                    VStack {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                            )
                        Text("Plugin \(index + 1)")
                            .font(.caption)
                    }
                    .frame(width: 80)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120) // Increase the height slightly for testing purposes
    }
}
