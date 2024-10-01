//
//  HashtagButton.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

// Helper view for individual hashtag buttons
struct HashtagButton: View {
    let text: String
    @Binding var selectedHashtag: String?

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(selectedHashtag == text || (selectedHashtag == nil && text == "#All") ? .red : .gray) // Red if selected or if "#All" is selected
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedHashtag == text || (selectedHashtag == nil && text == "#All") ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
            )
            .onTapGesture {
                if text == "#All" {
                    selectedHashtag = nil // Show all posts
                } else {
                    if selectedHashtag == text {
                        selectedHashtag = nil // Deselect if already selected
                    } else {
                        selectedHashtag = text // Select the tapped hashtag
                    }
                }
            }
    }
}
