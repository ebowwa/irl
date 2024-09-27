//
//  SocialPost.swift
//  irl
//
//  Created by Elijah Arbee on 9/26/24.
//
import Foundation

// #hashtags will be top subject for embeddings, user taps hashtag and all associated chats to the topic show up
// `user n` will be the abstracted viewing to enable plugins - so plugins name and profile image

// Model for the Post data
struct SocialPost: Identifiable, Codable {
    var id: String
    var username: String
    var isUser: Bool // Indicates if the post is by the current user
    var timeAgo: String
    var imageName: String
    var title: String // Title of the post
    var shortDescription: String // Short description of the post
    var likeCount: Int
    var dislikeCount: Int
    var isLiked: Bool
    var isDisliked: Bool
    var hashtags: [String] // Hashtags to associate topics

    // Function to convert the post to JSON
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let jsonData = try? encoder.encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
}
