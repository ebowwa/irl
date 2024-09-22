//
//  MainTabMenu.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
}

import SwiftUI

struct MainTabMenu: View {
    @Binding var selectedTab: Int
    @StateObject private var audioRecorderViewModel = AudioRecorderViewModel()
    @State private var showAllRecordings = false
    @State private var showSettings = false // State to control the visibility of settings within Home view
    
    let accentColor: Color
    let inactiveColor: Color
    let backgroundColor: Color
    
    let tabs: [TabItem] = [
        TabItem(title: "Live", icon: "waveform", selectedIcon: "waveform"),
        TabItem(title: "Home", icon: "house", selectedIcon: "house.fill"),
        TabItem(title: "Chats", icon: "bubble.left.and.bubble.right", selectedIcon: "bubble.left.and.bubble.right.fill")
    ]
    
    init(selectedTab: Binding<Int>, accentColor: Color, inactiveColor: Color, backgroundColor: Color) {
        self._selectedTab = selectedTab
        self.accentColor = accentColor
        self.inactiveColor = inactiveColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                EmotionAnalysisDashboard()
            }
            .tabItem {
                customTabItem(for: tabs[0], isSelected: selectedTab == 0)
            }
            .tag(0)

            NavigationView {
                HomeView(showSettings: $showSettings) // Pass the binding for showing settings
            }
            .tabItem {
                customTabItem(for: tabs[1], isSelected: selectedTab == 1)
            }
            .tag(1)

            NavigationView {
                AudioRecorderDebugMenuView()
                // BasicEmbeddingsView()
                //ChatView()
            }
            .tabItem {
                customTabItem(for: tabs[2], isSelected: selectedTab == 2)
            }
            .tag(2)
        }
        .accentColor(accentColor)
        .onAppear {
            setupAppearance()
        }
    }
    
    private func customTabItem(for tab: TabItem, isSelected: Bool) -> some View {
        VStack {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
            Text(tab.title)
        }
    }
    
    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(backgroundColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(inactiveColor)
    }
}


// Note: This view depends on:
// - ChatView, TabsView, and SettingsView for other tab content
// - AppState.swift for the shared app state (not shown in this file)
// - Models.swift for Theme and Language enums (used in AppState, not shown in this file)
