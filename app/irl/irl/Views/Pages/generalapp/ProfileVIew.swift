//
//  ProfileVIew.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: GlobalState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeaderView()
                ProfileStatsView()
                ProfileActivityFeed()
            }
        }
        .navigationBarTitle("Profile", displayMode: .inline)
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var appState: GlobalState

    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(Color("AccentColor"))
            Text(appState.user?.name ?? "Loading...")
                .font(.title)
            Text(appState.user?.email ?? "")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}

struct ProfileStatsView: View {
    var body: some View {
        HStack {
            Spacer()
            StatItem(value: "250", title: "Posts")
            Spacer()
            StatItem(value: "10K", title: "Followers")
            Spacer()
            StatItem(value: "1K", title: "Following")
            Spacer()
        }
        .padding()
        .background(Color("CardBackgroundColor"))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let value: String
    let title: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}

struct ProfileActivityFeed: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            List {
                ForEach(0..<10) { _ in
                    HStack {
                        Circle()
                            .fill(Color("AccentColor"))
                            .frame(width: 10, height: 10)
                        Text("Activity item")
                            .font(.subheadline)
                    }
                }
            }
            .frame(height: 300)
        }
        .background(Color("CardBackgroundColor"))
        .cornerRadius(12)
    }
}

// Note: This view and its components depend on AppState for user information and various custom color assets
