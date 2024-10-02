//
//  ChatsExample.swift
//  irl
//
//  Created by Elijah Arbee on 10/2/24.
//
import SwiftUI

// Updated model with articulated naming
struct DemoPostData: Identifiable {
    var id = UUID()
    var username: String
    var timeAgo: String
    var postImage: String
    var postTitle: String
    var postDescription: String
    var hashtags: [String]
    var likes: Int
    var hearts: Int
}

// Sample data using the renamed model
let sampleDemoPosts: [DemoPostData] = [
    DemoPostData(username: "Gianna A", timeAgo: "12m ago", postImage: "omi", postTitle: "Exploring SwiftUI", postDescription: "A deep dive into building responsive UIs with SwiftUI.", hashtags: ["#SwiftUI", "#iOS", "#Development"], likes: 10, hearts: 2),
    DemoPostData(username: "Alex B", timeAgo: "30m ago", postImage: "waveform", postTitle: "Live", postDescription: "", hashtags: [], likes: 0, hearts: 0),
    DemoPostData(username: "Elena C", timeAgo: "1h ago", postImage: "cityscape", postTitle: "Urban Exploration", postDescription: "Discovering hidden spots in the city.", hashtags: ["#Photography", "#Urban", "#Adventure"], likes: 34, hearts: 8),
    DemoPostData(username: "Michael D", timeAgo: "2h ago", postImage: "mountains", postTitle: "Into the Wild", postDescription: "Escaping the city for a peaceful retreat in the mountains.", hashtags: ["#Nature", "#Mountains", "#Travel"], likes: 57, hearts: 12)
]

struct ChatsView: View {
    @State private var selectedTag: String = "All"
    @State private var showDropDown: Bool = false
    @State private var hidePlugins: Bool = false
    @State private var scrollOffset: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with slight changes in design
            HStack {
                Text("kellyjane")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            
            // Plugins Horizontal ScrollView (disappears on scroll)
            if !hidePlugins {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(1..<5) { index in
                            VStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                Text("Plugin \(index)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, index == 1 ? 16 : 0)
                        }
                    }
                }
                .padding(.vertical)
                .transition(.slide)
            }
            
            // Tags/Filters always visible
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    TagButtonView(tag: "All", selectedTag: $selectedTag)
                    TagButtonView(tag: "SwiftUI", selectedTag: $selectedTag)
                    TagButtonView(tag: "iOS", selectedTag: $selectedTag)
                    TagButtonView(tag: "Development", selectedTag: $selectedTag)
                }
                .padding(.horizontal)
            }
            .background(Color(UIColor.systemGray6))
            
            Divider()
            
            // CPosts with scroll detection
            ScrollView {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            scrollOffset = geometry.frame(in: .global).minY
                        }
                        .onChange(of: geometry.frame(in: .global).minY) { newValue in
                            if newValue < scrollOffset {
                                withAnimation {
                                    hidePlugins = true
                                }
                            } else {
                                withAnimation {
                                    hidePlugins = false
                                }
                            }
                            scrollOffset = newValue
                        }
                }
                .frame(height: 0) // Invisible frame just for capturing scroll
                
                VStack(spacing: 12) {
                    ForEach(sampleDemoPosts) { post in
                        CPostView(post: post)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Bottom Bar with slight updates
            HStack {
                Spacer()
                Image(systemName: "message.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                    .padding()
            }
            .background(Color(UIColor.systemGray6))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct TagButtonView: View {
    var tag: String
    @Binding var selectedTag: String
    
    var body: some View {
        Button(action: {
            selectedTag = tag
        }) {
            Text("#\(tag)")
                .fontWeight(selectedTag == tag ? .bold : .regular)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundColor(selectedTag == tag ? .white : .gray)
                .background(selectedTag == tag ? Color.blue : Color.clear)
                .cornerRadius(15)
        }
    }
}

// Pulsating heart and thumbs down with gradient
struct CPostView: View {
    var post: DemoPostData
    @State private var pulsate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text(post.username)
                        .fontWeight(.medium)
                    Text(post.timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.blue)
                Text("Plugin")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if post.postImage != "" {
                Image(post.postImage)
                    .resizable()
                    .frame(height: 150)
                    .background(Color.cyan)
                    .cornerRadius(10)
            }
            
            Text(post.postTitle)
                .font(.headline)
            if !post.postDescription.isEmpty {
                Text(post.postDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                ForEach(post.hashtags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            
            // Heart and Thumbs down with gradient animation
            HStack(spacing: 16) {
                GradientPulsatingButton(imageName: "heart.fill")
                GradientPulsatingButton(imageName: "hand.thumbsdown.fill")
                Spacer()
                Image(systemName: "square.and.arrow.up.fill")
            }
            .font(.footnote)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// Gradient and pulsating animation for buttons
struct GradientPulsatingButton: View {
    var imageName: String
    @State private var pulsate = false
    
    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 24))
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.pink, Color.purple]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(30)
                    .shadow(color: Color.purple.opacity(0.6), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(pulsate ? 1.1 : 1.0)
            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsate)
            .onAppear {
                pulsate = true
            }
    }
}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView()
    }
}
