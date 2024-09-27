//
//  HashtagsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

// View for displaying hashtags
struct HashtagsView: View {
    @Binding var selectedHashtag: String? // Binds to the selected hashtag in the ViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                HashtagButton(text: "#All", selectedHashtag: $selectedHashtag)
                HashtagButton(text: "#SwiftUI", selectedHashtag: $selectedHashtag)
                HashtagButton(text: "#iOS", selectedHashtag: $selectedHashtag)
                HashtagButton(text: "#Development", selectedHashtag: $selectedHashtag)
                HashtagButton(text: "#Combine", selectedHashtag: $selectedHashtag)
                HashtagButton(text: "#Reactive", selectedHashtag: $selectedHashtag)
                // Add more hashtags as needed
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
    }
}
