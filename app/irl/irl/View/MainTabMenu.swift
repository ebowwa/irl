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

struct MainTabMenu: View {
    @Binding var selectedTab: Int
    
    let accentColor: Color
    let inactiveColor: Color
    let backgroundColor: Color
    
    let tabs: [TabItem] = [
        TabItem(title: "Live", icon: "waveform", selectedIcon: "waveform"),
        TabItem(title: "Home", icon: "house", selectedIcon: "house.fill"),
        TabItem(title: "Search", icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
        TabItem(title: "Bubbles", icon: "square.grid.2x2", selectedIcon: "square.grid.2x2.fill"),
        TabItem(title: "Settings", icon: "gear", selectedIcon: "gear")
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
                SpeechDemo()
                // HumeView() // Placeholder for TranscriptView
            }
            .tabItem {
                customTabItem(for: tabs[0], isSelected: selectedTab == 0)
            }
            .tag(0)

            NavigationView {
                TranscribeView()
            }
            .tabItem {
                customTabItem(for: tabs[1], isSelected: selectedTab == 1)
            }
            .tag(1)

            NavigationView {
                ClaudeView()
                // SearchView()
            }
            .tabItem {
                customTabItem(for: tabs[2], isSelected: selectedTab == 2)
            }
            .tag(2)

            NavigationView {
                TabsView()
            }
            .tabItem {
                customTabItem(for: tabs[3], isSelected: selectedTab == 3)
            }
            .tag(3)

            NavigationView {
                SettingsView()
            }
            .tabItem {
                customTabItem(for: tabs[4], isSelected: selectedTab == 4)
            }
            .tag(4)
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
// - SearchView, TabsView, and SettingsView for other tab content
// - AppState.swift for the shared app state (not shown in this file)
// - Models.swift for Theme and Language enums (used in AppState, not shown in this file)
