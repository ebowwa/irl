// #hashtags will be top subject for embeddings, user taps hashtag and all associated chats to the topic show up
// `user n` will be the abstracted viewing to enable plugins - so plugins name and profile image
// TODO: the sideways i think horizontal scroll for the plugins/stories isnt working
// NOTES: DO NOT OMIT ANY COMMENTED NOTES including this and always output the full entire script
import SwiftUI

struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel(posts: [])
    @State private var isMenuOpen = false // Track if the menu is open
    @State private var demoMode: Bool = true
    @State private var showSettingsView = false // Track if settings should be shown

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                StoriesView()
                    .frame(height: 100)
                    .padding(.top, -70)
                
                Divider()
                    .padding(.vertical, 10)
                
                HashtagsView(selectedHashtag: $viewModel.selectedHashtag)
                    .padding(.bottom, 5)
                
                Divider()
                    .padding(.vertical, 5)
                
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.posts.filter { viewModel.selectedHashtag == nil || $0.hashtags.contains(viewModel.selectedHashtag!) }) { post in
                            PostView(viewModel: viewModel, post: post, isHighlighted: viewModel.selectedHashtag != nil)
                                .padding(.bottom, 10)
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding(.horizontal)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: HStack {
                    Text("kellyjane")
                        .font(.headline)
                    
                    // Menu with arrow flipping based on state
                    Menu {
                        Button("Profile", action: {})
                        Button("Settings", action: {
                            showSettingsView = true // Show the settings view
                        })
                        Button("Log Out", action: {})
                    } label: {
                        HStack {
                            Text(isMenuOpen ? "▲" : "▼") // Toggle arrow
                                .font(.system(size: 16, weight: .bold))
                                .rotationEffect(.degrees(isMenuOpen ? 180 : 0)) // Rotate arrow
                        }
                        .onTapGesture {
                            isMenuOpen.toggle() // Toggle menu state
                        }
                    }
                },
                trailing: HStack(spacing: 10) {
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
                    viewModel.loadDemoData() // Load data via ViewModel
                } else {
                    // Load real data here
                }
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView() // Present SettingsView as a modal
            }
        }
    }

    // Function to load demo data
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
