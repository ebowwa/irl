//
//  SocialFeedViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import SwiftUI

// ViewModel for handling post interactions
class SocialFeedViewModel: ObservableObject {
    @Published var posts: [SocialPost] // Handles multiple posts
    @Published var selectedHashtag: String? // Tracks the selected hashtag

    init(posts: [SocialPost]) {
        self.posts = posts
    }

    // Toggles the like status of a post
    func toggleLike(for post: SocialPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                posts[index].isLiked.toggle()
                posts[index].likeCount += posts[index].isLiked ? 1 : -1
                if posts[index].isDisliked && posts[index].isLiked {
                    posts[index].isDisliked = false
                    posts[index].dislikeCount -= 1
                }
            }
        }
    }

    // Toggles the dislike status of a post
    func toggleDislike(for post: SocialPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                posts[index].isDisliked.toggle()
                posts[index].dislikeCount += posts[index].isDisliked ? 1 : -1
                if posts[index].isLiked && posts[index].isDisliked {
                    posts[index].isLiked = false
                    posts[index].likeCount -= 1
                }
            }
        }
    }

    // Loads demo data from JSON
    func loadDemoData() {
        if let url = Bundle.main.url(forResource: "DemoData", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let demoPosts = try JSONDecoder().decode(DemoPosts.self, from: data)
                self.posts = demoPosts.posts.map { $0.toSocialPost() }
            } catch {
                print("Error loading demo data: \(error)")
            }
        }
    }

    // Converts all posts to JSON
    func getAllPostsJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let jsonData = try? encoder.encode(posts) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
}

// Models to decode JSON data
struct DemoPosts: Codable {
    let posts: [DemoPost]
}
struct DemoPost: Codable {
    let id: String
    let username: String
    let isUser: Bool
    let timeAgo: String
    let imageName: String
    let title: String
    let shortDescription: String
    let likeCount: Int
    let dislikeCount: Int
    let isLiked: Bool
    let isDisliked: Bool
    let hashtags: [String]
    
    func toSocialPost() -> SocialPost {
        return SocialPost(
            id: id,
            username: username,
            isUser: isUser,
            timeAgo: timeAgo,
            imageName: imageName,
            title: title,
            shortDescription: shortDescription,
            likeCount: likeCount,
            dislikeCount: dislikeCount,
            isLiked: isLiked,
            isDisliked: isDisliked,
            hashtags: hashtags
        )
    }
}
