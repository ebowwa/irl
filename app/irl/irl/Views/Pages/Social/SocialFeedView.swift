
// #hashtags will be top subject for embeddings, user taps hashtag and all associated chats to the topic show up
// `user n` will be the abstracted viewing to enable plugins - so plugins name and profile image
// TODO: the sideways i think horizontal scroll for the plugins/stories isnt working 
// NOTES: DO NOT OMIT ANY COMMENTED NOTES including this and always output the full entire script
import SwiftUI

// #hashtags will be top subject for embeddings, user taps hashtag and all associated chats to the topic show up
// user n will be the abstracted viewing to enable plugins - so plugins name and profile image
// TODO: the sideways i think horizontal scroll for the plugins/stories isnt working
// NOTES: DO NOT OMIT ANY COMMENTED NOTES including this and always output the full entire script

// The main view for displaying the social feed
struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel(
        posts: []
    )
    
    // Demo mode flag
    @State private var demoMode: Bool = true // Make demo mode bool to true, with demo mode using the demo data
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Stories Scroll View
                StoriesView()
                    .frame(height: 100) // Fixed height to ensure proper layout
                    .padding(.top, -70) // Adjusted padding
                
                Divider() // Added divider for better separation
                    .padding(.vertical, 10)
                
                // Hashtags
                HashtagsView(selectedHashtag: $viewModel.selectedHashtag)
                    .padding(.bottom, 5) // Adjust spacing to bring hashtags higher
                
                Divider()
                    .padding(.vertical, 5)
                
                // Feed Posts
                ScrollView {
                    LazyVStack {
                        // Filter posts based on selected hashtag
                        ForEach(viewModel.posts.filter { viewModel.selectedHashtag == nil || $0.hashtags.contains(viewModel.selectedHashtag!) }) { post in
                            PostView(viewModel: viewModel, post: post, isHighlighted: viewModel.selectedHashtag != nil)
                                .padding(.bottom, 10)
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding(.horizontal) // Added horizontal padding for better layout
            .navigationTitle("kellyjane")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing:
                    HStack(spacing: 10) { // Reduce spacing between AI and magnifying glass icons
                        // Added AI button circle as per TODO
                        NavigationLink(destination: ChatView()) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "brain.head.profile")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }
                    }
            )
            .onAppear {
                if demoMode {
                    loadDemoData()
                } else {
                    // Load real data here
                }
            }
        }
    }
    
    // Function to load demo data from JSON
    func loadDemoData() {
        if let url = Bundle.main.url(forResource: "DemoData", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let demoPosts = try JSONDecoder().decode(DemoPosts.self, from: data)
                viewModel.posts = demoPosts.posts.map { $0.toSocialPost() }
            } catch {
                print("Error loading demo data: \(error)")
            }
        }
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

struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SocialFeedView()
    }
}
