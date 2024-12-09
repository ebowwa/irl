import SwiftUI
/** TODO:
    - add daily streak
    - add award icons
 
 ### USER PERSISTANCE
 - pfp bucket
 - cloud db sync
 
 */
struct ProfileView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var userProfileVM = UserProfileViewModel.shared
    @StateObject private var userManager = UserManager.shared
    @State private var showingSettings = false
    
    private var joinDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Joined \(formatter.string(from: userManager.joinDate))"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Image and Name
                    VStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.purple)
                        
                        Text(userProfileVM.username)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(joinDateFormatted)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    HStack(spacing: 40) {
                        StatView(value: "\(userManager.moments)", label: "Moments")
                        StatView(value: String(format: "%.1fh", userManager.hoursListened), label: "Listened")
                        StatView(value: "\(userManager.growthPercentage)%", label: "Growth")
                    }
                    .padding(.vertical)
                    
                    // Collections Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(0..<4) { _ in
                            CollectionCard()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
        }
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CollectionCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .overlay(
                Text("Collection")
                    .foregroundColor(.secondary)
            )
            .frame(height: 150)
    }
}
/**
 struct ProfileView_Previews: PreviewProvider {
 static var previews: some View {
 ProfileView()
 .environmentObject(AppSettings())
 }
 }
 */
