//
//  PostView.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

// View for an individual Post
struct PostView: View {
    @ObservedObject var viewModel: SocialFeedViewModel
    var post: SocialPost
    var isHighlighted: Bool // Indicates if the post should be highlighted based on hashtag selection

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .fill(post.isUser ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5)) // Different color if post is by the user
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading) {
                    Text(post.username)
                        .font(.headline)
                    Text(post.timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if post.isUser {
                    // Display plugin name and profile image for user posts
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.blue)
                        Text("Plugin")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding([.top, .horizontal])

            // Image Post with Proper Constraints
            Image(post.imageName)
                .resizable()
                .scaledToFit() // Fit within the frame without overflowing
                .frame(maxHeight: 300)
                .clipped() // Ensures that it doesn't take extra space
                .padding(.horizontal) // Ensure there is some padding

            // Post Title
            Text(post.title)
                .font(.subheadline) // Reduced font size
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top, 5)

            // Post Short Description
            Text(post.shortDescription)
                .font(.caption) // Smaller font size
                .foregroundColor(.secondary)
                .padding([.horizontal, .bottom])

            // Hashtags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(post.hashtags, id: \.self) { hashtag in
                        Text(hashtag)
                            .font(.caption)
                            .foregroundColor(viewModel.selectedHashtag == hashtag ? .red : .blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(viewModel.selectedHashtag == hashtag ? Color.red : Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
            }

            // Like/Dislike Count and Buttons
            HStack {
                Text("\(post.likeCount)") // Likes
                    .font(.subheadline)
                    .padding(.leading)

                Button(action: {
                    viewModel.toggleLike(for: post)
                }) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(post.isLiked ? .red : .gray)
                        .scaleEffect(post.isLiked ? 1.2 : 1.0)
                }
                .padding(.leading, 5) // Reduced spacing between count and button

                Text("\(post.dislikeCount)") // Dislikes
                    .font(.subheadline)
                    .padding(.leading, 20) // Reduced spacing between elements

                Button(action: {
                    viewModel.toggleDislike(for: post)
                }) {
                    Image(systemName: post.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(post.isDisliked ? .blue : .gray)
                        .scaleEffect(post.isDisliked ? 1.2 : 1.0)
                }
                .padding(.leading, 5) // Reduced spacing between count and button
            }
            .padding(.vertical, 10)
        }
        .background(isHighlighted ? Color.red.opacity(0.1) : Color.white) // Highlight if a hashtag is selected
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}
