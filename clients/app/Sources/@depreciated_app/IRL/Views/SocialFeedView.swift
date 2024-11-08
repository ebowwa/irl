// #hashtags will be top subject for embeddings, user taps hashtag and all associated chats to the topic show up
// `user n` will be the abstracted viewing to enable plugins - so plugins name and profile image
// TODO: the sideways i think horizontal scroll for the plugins/stories isnt working
// NOTES: DO NOT OMIT ANY COMMENTED NOTES including this and always output the full entire script
// File 4: SocialFeedView.swift

import SwiftUI

struct SocialFeedView: View {
    // Use @Binding to receive state from parent
    @ObservedObject var viewModel: SocialFeedViewModel
    @Binding var isMenuOpen: Bool
    @Binding var demoMode: Bool
    @Binding var showSettingsView: Bool
    
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
        }
    }
}

struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for previews
        let viewModel = SocialFeedViewModel(posts: [])
        SocialFeedView(
            viewModel: viewModel,
            isMenuOpen: .constant(false),
            demoMode: .constant(true),
            showSettingsView: .constant(false)
        )
    }
}
