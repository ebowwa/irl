import SwiftUI

struct AnalyticsExampleView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Analytics Example")
                    .font(.title)
                
                // Example button that tracks user action
                Button("Start Session") {
                    // This will send an event to Google Analytics
                    AnalyticsService.shared.logUserAction(
                        action: "start_session",
                        category: "session_management"
                    )
                }
                .buttonStyle(.borderedProminent)
                
                // Example navigation that tracks screen view
                NavigationLink("Go to Profile") {
                    ProfileView()
                }
            }
            .padding()
            // This tracks when this screen appears
            .analyticsScreen("main_screen")
        }
    }
}

// Example of a screen that tracks views
struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile")
                .font(.title)
            
            Button("Update Profile") {
                // Track profile update action
                AnalyticsService.shared.logEvent(
                    name: "profile_update",
                    parameters: [
                        "source": "profile_screen",
                        "timestamp": Date().timeIntervalSince1970
                    ]
                )
            }
        }
        // This automatically tracks when the profile screen is viewed
        .analyticsScreen("profile_screen")
    }
}

#Preview {
    AnalyticsExampleView()
}
