//
//  DashboardView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//  Updated on 8/30/24.
//
/** TODO:
    - most of this will be removed it doesnt serve our app
    - Needs to have indicators of the user's life, daily mood, challenges, patterns, interesting moments, every user's life tells a story - we need to articulate the story
    - traits found in your speech prosody & transcriptions
    - traits found of those you engage with
    - invite your friends
    - share memories
    - collaborate on memories
    - instant assistant
    - compete with world and friends on productivity, good vibes, interactions
    - daily summary with images
*/
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var globalState: GlobalState
    @State private var showingNotifications = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView(title: "Dashboard")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<6) { index in
                        CardView(
                            title: "Card \(index + 1)",
                            description: "Description for card \(index + 1)",
                            buttonText: "Learn More",
                            buttonAction: {
                                print("Button tapped for card \(index + 1)")
                            }
                        )
                    }
                }
                .padding()

                ChartCardView(title: "Monthly Revenue", data: [0.2, 0.4, 0.3, 0.5, 0.4, 0.6])
                    .frame(height: 300)
                    .padding()

                RecentActivityCardView(activities: [
                    "Activity 1",
                    "Activity 2",
                    "Activity 3",
                    "Activity 4",
                    "Activity 5"
                ])
            }
        }
        .navigationBarItems(trailing: NotificationButton(showingNotifications: $showingNotifications))
        .sheet(isPresented: $showingNotifications) {
            NotificationView()
        }
    }
}

struct HeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationButton: View {
    @EnvironmentObject var globalState: GlobalState
    @Binding var showingNotifications: Bool

    var body: some View {
        Button(action: {
            showingNotifications.toggle()
        }) {
            Image(systemName: "bell.fill")
                .foregroundColor(Color("AccentColor"))
                .overlay(
                    Group {
                        if !globalState.notifications.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 10, y: -10)
                        }
                    }
                )
        }
    }
}

struct NotificationView: View {
    @EnvironmentObject var globalState: GlobalState

    var body: some View {
        NavigationView {
            List(globalState.notifications) { notification in
                VStack(alignment: .leading) {
                    Text(notification.title)
                        .font(.headline)
                    Text(notification.body)
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryTextColor"))
                }
            }
            .navigationBarTitle("Notifications", displayMode: .inline)
        }
    }
}

// Note: This view and its components depend on GlobalState and various custom color assets
