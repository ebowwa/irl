import SwiftUI
import Speech

struct TranscriptionView: View {
    @ObservedObject var tabViewModel: TabViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                Text(tabViewModel.transcriptionText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
            
            HStack {
                Button(action: {
                    if tabViewModel.isTranscribing {
                        tabViewModel.stopTranscription()
                    } else {
                        tabViewModel.startTranscription()
                    }
                }) {
                    Image(systemName: tabViewModel.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(tabViewModel.isTranscribing ? .red : .purple)
                }
                .padding()
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var tabViewModel = TabViewModel()
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        TabView(selection: $tabViewModel.selectedTab) {
            TimelineView()
                .tabItem {
                    Label(Tab.timeline.title, systemImage: Tab.timeline.icon)
                }
                .tag(Tab.timeline)
            ExploreView()
            // ImageGenerationView()
                .tabItem {
                    Label(Tab.explore.title, systemImage: Tab.explore.icon)
                }
                .tag(Tab.explore)
            
            TranscriptionView(tabViewModel: tabViewModel)
                .tabItem {
                    Label(Tab.record.title, systemImage: Tab.record.icon)
                }
                .tag(Tab.record)
            
            NotificationsView()
                .tabItem {
                    Label(Tab.notifications.title, systemImage: Tab.notifications.icon)
                }
                .tag(Tab.notifications)
            
            ProfileView()
                .tabItem {
                    Label(Tab.profile.title, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(.purple)
        .preferredColorScheme(settings.darkModeEnabled ? .dark : .light)
        .animation(.easeInOut(duration: 0.2), value: settings.darkModeEnabled)
    }
}

#Preview {
    ContentView()
}
