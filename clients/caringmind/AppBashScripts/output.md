# Local Repository to Text Conversion

This markdown file contains a structured representation of the local directory:
`.`

Below is a formatted listing of all Swift files and their contents:

## SettingsViewModel.swift
```swift
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notificationsEnabled: Bool
    @Published var darkModeEnabled: Bool
    @Published var soundEnabled: Bool
    @Published var devModeEnabled: Bool
    @Published var showTutorial: Bool = false
    @Published var isPresented: Bool = false // To control the presentation state
    @Published var showingSignOutAlert: Bool = false
    
    // MARK: - Dependencies
    private let authService: GoogleAuthService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(settings: AppSettings = .shared, authService: GoogleAuthService = .shared) {
        self.notificationsEnabled = settings.notificationsEnabled
        self.darkModeEnabled = settings.darkModeEnabled
        self.soundEnabled = settings.soundEnabled
        self.devModeEnabled = settings.devModeEnabled
        self.authService = authService
        
        // Sync changes back to AppSettings
        $notificationsEnabled
            .sink { settings.notificationsEnabled = $0 }
            .store(in: &cancellables)
        
        $darkModeEnabled
            .sink { settings.darkModeEnabled = $0 }
            .store(in: &cancellables)
        
        $soundEnabled
            .sink { settings.soundEnabled = $0 }
            .store(in: &cancellables)
        
        $devModeEnabled
            .sink { settings.devModeEnabled = $0 }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func signOut() async throws {
        try await authService.signOut()
        // Additional actions after sign out can be handled here if needed
    }
    
    func postSignOutNotification() {
        NotificationCenter.default.post(name: NSNotification.Name("SignOutNotification"), object: nil)
    }
    
    // Add other actions as needed, e.g., openTutorial, resetAppState, etc.
}
```

## UserProfileViewModel.swift
```swift
import SwiftUI

class UserProfileViewModel: ObservableObject {
    static let shared = UserProfileViewModel()
    private let defaults = UserDefaults.standard
    private let usernameKey = "user_name"
    
    @Published var username: String = "Your Name"
    
    private init() {
        refreshUsername()
    }
    
    func refreshUsername() {
        if let storedUsername = defaults.string(forKey: usernameKey) {
            DispatchQueue.main.async {
                self.username = storedUsername
            }
        }
    }
    
    func saveUsername(_ name: String) {
        defaults.set(name, forKey: usernameKey)
        refreshUsername()
    }
    
    func clearUsername() {
        defaults.removeObject(forKey: usernameKey)
        DispatchQueue.main.async {
            self.username = "Your Name"
        }
    }
}
```

## TimelineState.swift
```swift
import SwiftUI

class TimelineState: ObservableObject {
    static let shared = TimelineState()
    private let defaults = UserDefaults.standard
    private let momentsKey = "timeline_moments"
    
    @Published var moments: [Moment] = []
    @Published var isRecording = false
    
    private init() {
        loadMoments()
    }
    
    private func loadMoments() {
        if let data = defaults.data(forKey: momentsKey),
           let decodedMoments = try? JSONDecoder().decode([Moment].self, from: data) {
            moments = decodedMoments
        }
    }
    
    private func saveMoments() {
        if let encoded = try? JSONEncoder().encode(moments) {
            defaults.set(encoded, forKey: momentsKey)
        }
    }
    
    func addMoment(_ moment: Moment) {
        moments.insert(moment, at: 0)  // Add new moments at the top
        saveMoments()
    }
    
    func addInitialMoment(from response: ServerResponse) {
        let moment = Moment.voiceAnalysis(
            name: response.name,
            prosody: response.prosody,
            feeling: response.feeling,
            confidenceScore: response.confidence_score,
            analysis: response.psychoanalysis,
            extraData: [
                "confidence_reasoning": response.confidence_reasoning,
                "location_background": response.location_background
            ]
        )
        addMoment(moment)
    }
    
    func clearMoments() {
        moments.removeAll()
        saveMoments()
    }
}
```

## TabViewModel.swift
```swift
import SwiftUI

enum Tab: Int, CaseIterable {
    case timeline
    case explore
    case record
    case notifications
    case profile
    
    var title: String {
        switch self {
        case .timeline: return "Timeline"
        case .explore: return "Explore"
        case .record: return "Record"
        case .notifications: return "Activity"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .timeline: return "clock.fill"
        case .explore: return "sparkles"
        case .record: return "waveform.circle.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

@MainActor
final class TabViewModel: ObservableObject {
    @Published var selectedTab: Tab = .timeline
    
    // Computed properties for tab-specific states
    var isRecordingEnabled: Bool {
        selectedTab == .record
    }
    
    // Tab selection handling
    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
}
```

## AuthenticationViewModel.swift
```swift
import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = GoogleAuthService.shared) {
        self.authService = authService
    }
    
    func signInWithGoogle() {
        Task {
            do {
                user = try await authService.signInWithGoogle()
                isAuthenticated = true
                UserDefaults.standard.set(true, forKey: "isSignedIn")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                user = nil
                isAuthenticated = false
                UserDefaults.standard.set(false, forKey: "isSignedIn")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

## caringApp.swift
```swift
//
//  caringApp.swift
//  caring
//
//  Created by Elijah Arbee on 12/1/24.
//

//
//  caringApp.swift
//  caring
//
//  Created by Elijah Arbee on 12/1/24.
//

import SwiftUI

@main
struct caringApp: App {
    // @AppStorage("isSignedIn") private var isSignedIn = false
    @StateObject private var settings = AppSettings.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settings.darkModeEnabled ? .dark : .light)
                .animation(.easeInOut(duration: 0.2), value: settings.darkModeEnabled)
        }
    }
}
```

## ServerResponse.swift
```swift
// TODO: this may be redundant i.e. this is redeclared from the moments and idk which is in use
import Foundation

struct ServerResponse: Codable {
    let name: String
    let prosody: String
    let feeling: String
    let confidence_score: Int
    let confidence_reasoning: String
    let psychoanalysis: String
    let location_background: String
    
    // Safe accessors with default values
    var safeName: String { name }
    var safeProsody: String { prosody }
    var safeFeeling: String { feeling }
    var safeConfidenceScore: Int { confidence_score }
    var safeConfidenceReasoning: String { confidence_reasoning }
    var safePsychoanalysis: String { psychoanalysis }
    var safeLocationBackground: String { location_background }
}

// Preview helper
extension ServerResponse {
    static let preview = ServerResponse(
        name: "Alex",
        prosody: "Confident and clear",
        feeling: "Positive",
        confidence_score: 85,
        confidence_reasoning: "Clear pronunciation and steady pace",
        psychoanalysis: "Shows self-assurance in voice",
        location_background: "Quiet environment"
    )
}
```

## Moment.swift
```swift
import Foundation

struct Moment: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: String
    var metadata: [String: Any]
    var interactions: [String: Any]
    var tags: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, metadata, interactions, tags
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), category: String, metadata: [String: Any], interactions: [String: Any] = [:], tags: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.metadata = metadata
        self.interactions = interactions
        self.tags = tags
    }
    
    // MARK: - Codable Implementation
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        category = try container.decode(String.self, forKey: .category)
        tags = try container.decode([String].self, forKey: .tags)
        
        let metadataData = try container.decode(Data.self, forKey: .metadata)
        metadata = (try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]) ?? [:]
        
        let interactionsData = try container.decode(Data.self, forKey: .interactions)
        interactions = (try JSONSerialization.jsonObject(with: interactionsData) as? [String: Any]) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
        
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try container.encode(metadataData, forKey: .metadata)
        
        let interactionsData = try JSONSerialization.data(withJSONObject: interactions)
        try container.encode(interactionsData, forKey: .interactions)
    }
    
    // MARK: - Voice Analysis // rename to Name Input 
    
    static func voiceAnalysis(
        name: String,
        prosody: String,
        feeling: String,
        confidenceScore: Int,
        analysis: String,
        extraData: [String: Any] = [:]
    ) -> Moment {
        var metadata: [String: Any] = [
            "name": name,
            "prosody": prosody,
            "feeling": feeling,
            "confidence_score": confidenceScore,
            "analysis": analysis
        ]
        metadata.merge(extraData) { (_, new) in new }
        
        return Moment(
            category: "voice_analysis",
            metadata: metadata,
            tags: ["voice", feeling.lowercased()]
        )
    }
}```

## Color+Hex.swift
```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## ExploreView.swift
```swift
import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<10) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                            .overlay {
                                Text("Trending Moment")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Explore")
        }
    }
}
```

## SettingsView.swift
```swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    @AppStorage("isSignedIn") private var isSignedIn = false
    
    var body: some View {
        NavigationView {
            List {
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
                    Toggle("Sound Effects", isOn: $viewModel.soundEnabled)
                }
                
                // Account Section
                Section(header: Text("Account")) {
                    Button(action: {
                        // Implement account settings
                    }) {
                        Label("Account Settings", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        // Implement privacy settings
                    }) {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    Button(action: {
                        // Implement help center
                    }) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        // Implement contact support
                    }) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }
                
                // Developer Options Section
                Section(header: Text("Developer Options")) {
                    Toggle("Developer Mode", isOn: $viewModel.devModeEnabled)
                    
                    if viewModel.devModeEnabled {
                        Button(action: {
                            viewModel.showTutorial = true
                        }) {
                            Label("Open Tutorial", systemImage: "book.fill")
                        }
                        
                        NavigationLink(destination: Text("Debug Console")) {
                            Label("Debug Console", systemImage: "terminal.fill")
                        }
                        
                        Button(action: {
                            // Reset app state for testing
                        }) {
                            Label("Reset App State", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button(action: {
                            // Clear cache
                        }) {
                            Label("Clear Cache", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        viewModel.showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                viewModel.isPresented = false
                dismiss()
            })
            .sheet(isPresented: $viewModel.showTutorial) {
                TutorialView()
            }
            .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.signOut()
                            isSignedIn = false
                            viewModel.postSignOutNotification()
                            dismiss()
                        } catch {
                            print("Error signing out: \(error)")
                            // Optionally, present an error alert to the user
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .environment(\.colorScheme, viewModel.darkModeEnabled ? .dark : .light)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
```

## ProfileView.swift
```swift
import SwiftUI
/** TODO:
    - add daily streak
    - add award icons
 
 ### USER PERSISTANCE
 - pfp bucket
 - cloud db sync
 
 */
struct ProfileView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var userProfileVM = UserProfileViewModel.shared
    @State private var joinDate: String = "Joined December 2023"
    
    // Stats
    @State private var moments: Int = 247
    @State private var hoursListened: Double = 14.2
    @State private var growthPercentage: Int = 89
    
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
                        
                        Text(joinDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    HStack(spacing: 40) {
                        StatView(value: "\(moments)", label: "Moments")
                        StatView(value: "\(hoursListened)h", label: "Listened")
                        StatView(value: "\(growthPercentage)%", label: "Growth")
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
                        settings.isPresented = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $settings.isPresented) {
                SettingsView()
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
```

## TimelineView.swift
```swift
import SwiftUI

struct TimelineView: View {
    @StateObject private var timelineState = TimelineState.shared
    @State private var searchText = ""
    
    var filteredMoments: [Moment] {
        if searchText.isEmpty {
            return timelineState.moments
        } else {
            return timelineState.moments.filter { moment in
                // Search in metadata and tags
                let metadataString = moment.metadata.description.lowercased()
                let tagsString = moment.tags.joined(separator: " ").lowercased()
                return metadataString.contains(searchText.lowercased()) ||
                       tagsString.contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMoments) { moment in
                    MomentCard(moment: moment)
                }
            }
            .searchable(text: $searchText, prompt: "Search moments...")
            .navigationTitle("Timeline")
        }
    }
}

#Preview {
    TimelineView()
}
```

## NotificationsView.swift
```swift
import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<5) { _ in
                    HStack {
                        Circle()
                            .fill(.purple)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading) {
                            Text("New Insight Available")
                                .font(.headline)
                            Text("2m ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Activity")
        }
    }
}
```

## TruthLieGameView.swift
```swift
//
//  TruthLieGameView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/5/24.
// TODO:
// 1. - once the audio is sent, unless the audio fails, remove the begin button post user speech/when not needed i.e. like at summary
// 2. - once pressed and uploaded, do not show the begin button anymore
// 3. - should gather feedback about whether the result was accurate or incorrect

import SwiftUI

// MARK: 1. Reusable Card View
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    Color.black
                    // Circuit pattern design
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            // Create circuit pattern with random elements
                            path.move(to: CGPoint(x: 0, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
                            
                            path.move(to: CGPoint(x: width, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
                            
                            // Additional circuit elements
                            for i in stride(from: 0, to: width, by: 40) {
                                if Bool.random() {
                                    path.move(to: CGPoint(x: i, y: 0))
                                    path.addLine(to: CGPoint(x: i + 20, y: 20))
                                }
                            }
                        }
                        .stroke(Color(hex: "#00FF00").opacity(0.1), lineWidth: 0.5)
                    }
                }
            )
            .cornerRadius(15)
            .shadow(color: Color(hex: "#00FF00").opacity(0.2), radius: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(hex: "#00FF00").opacity(0.3), lineWidth: 1)
            )
            .frame(maxWidth: 350, maxHeight: 500)
    }
}

// MARK: 2. Swipeable Card View
struct SwipeableCardView: View {
    let statement: StatementAnalysis
    let onSwipe: (_ direction: AnalysisService.SwipeDirection, _ statement: StatementAnalysis) -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var glowIntensity: Double = 0

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    if statement.isTruth {
                        Text("truth")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color(hex: "#00FF00"))
                    } else {
                        Text("deception")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))
                        Spacer()
                        Image(systemName: "wand.and.rays")
                            .foregroundColor(Color(hex: "#00FF00"))
                    }
                }

                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.3))

                Text(statement.statement)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
                
                // Swipe instruction hint
                Text("< swipe to analyze >")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00").opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            }
            .padding()
        }
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 10)))
        .gesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    self.offset = gesture.translation
                }
                .onEnded { gesture in
                    let swipeThreshold: CGFloat = 100
                    if gesture.translation.width > swipeThreshold {
                        withAnimation {
                            self.offset = CGSize(width: 1000, height: 0)
                        }
                        onSwipe(.right, statement)
                    } else if gesture.translation.width < -swipeThreshold {
                        withAnimation {
                            self.offset = CGSize(width: -1000, height: 0)
                        }
                        onSwipe(.left, statement)
                    } else {
                        withAnimation {
                            self.offset = .zero
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: offset)
    }
}

// MARK: 3. Main Analysis View
struct TruthLieGameView: View {
    @Binding var step: Int
    @StateObject private var service = AnalysisService()
    @State private var showInstructions = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                recordingContainer
                
                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.3))
                
                ZStack {
                    if service.showSummary {
                        summaryCard
                            .transition(.opacity)
                    } else {
                        if service.statements.filter({ !service.swipedStatements.contains($0.id) }).isEmpty && service.response != nil {
                            Text("analysis complete")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                        } else {
                            ForEach(service.statements) { statement in
                                if !service.swipedStatements.contains(statement.id) {
                                    SwipeableCardView(statement: statement) { direction, swipedStatement in
                                        service.handleSwipe(direction: direction, for: swipedStatement)
                                    }
                                    .stacked(at: index(of: statement), in: service.statements.count)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if showInstructions {
                    instructionsOverlay
                }
            }
        )
        .alert(item: $service.recordingError) { error in
            Alert(
                title: Text("error"),
                message: Text(error.message),
                dismissButton: .default(Text("retry"))
            )
        }
    }

    // MARK: 4. Recording Container
    private var recordingContainer: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("truth protocol")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
                
                Text("tell me two truths and a lie")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
                
                Button(action: { showInstructions.toggle() }) {
                    Label("how to play", systemImage: "info.circle")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00").opacity(0.6))
                }
            }
            
            Button(action: {
                if service.isRecording {
                    service.stopRecording()
                    service.uploadRecording()
                } else {
                    service.startRecording()
                }
            }) {
                HStack {
                    Image(systemName: service.isRecording ? "stop.circle" : "waveform.circle")
                    Text(service.isRecording ? "analyzing..." : "begin")
                }
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(service.isRecording ? .black : Color(hex: "#00FF00"))
                .frame(width: 280, height: 56)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(service.isRecording ? Color(hex: "#00FF00") : Color.black)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    }
                )
            }

            if let response = service.response {
                Text("statements detected. swipe to analyze.")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
            }
        }
        .padding()
    }

    // MARK: 5. Instructions Overlay
    private var instructionsOverlay: some View {
        VStack(spacing: 20) {
            Text("how to play")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            
            VStack(alignment: .leading, spacing: 15) {
                Text("1. tap begin and state three things about yourself")
                Text("2. two statements should be true, one should be false")
                Text("3. speak clearly and naturally")
                Text("4. tap again when finished")
                Text("5. swipe cards to analyze each statement")
            }
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            
            Button("got it") {
                showInstructions = false
            }
            .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
        .padding()
        .foregroundColor(Color(hex: "#00FF00"))
        .background(Color.black.opacity(0.95))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(hex: "#00FF00"), lineWidth: 1)
        )
        .padding()
    }

    // MARK: 5. Summary Card
    private var summaryCard: some View {
            CardView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("final analysis")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))

                        if let response = service.response {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("accuracy")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Spacer()
                                    Text(String(format: "%.0f%%", response.finalConfidenceScore * 100))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(Color(hex: "#00FF00"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("analysis")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Text(response.guessJustification)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                }
                                .foregroundColor(Color(hex: "#00FF00"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("insight")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Text(response.responseMessage)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                }
                                .foregroundColor(Color(hex: "#00FF00"))

                                Spacer(minLength: 20)

                                Button(action: service.resetSwipes) {
                                    Text("analyze again")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(hex: "#00FF00"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                                        )
                                }

                                Button(action: { step += 1 }) {
                                    Text("continue >>")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "#00FF00"))
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Text("no data available")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                        }
                    }
                    .padding()
                }
            }
            .transition(.opacity)
        }
        // MARK: 6. Helper Functions
        private func index(of statement: StatementAnalysis) -> Int {
            service.statements.firstIndex(where: { $0.id == statement.id }) ?? 0
        }
    }

    // MARK: 7. View Extension for Stacking Effect
    extension View {
        func stacked(at position: Int, in total: Int) -> some View {
            let offset = Double(total - position) * 10
            return self.offset(CGSize(width: 0, height: offset))
        }
    }

    // MARK: 8. Preview Provider
    struct TruthLieGameView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                TruthLieGameView(step: .constant(6))
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: 9. Animation Extension
    extension Animation {
        static var cardSpring: Animation {
            .spring(response: 0.4, dampingFraction: 0.7)
        }
    }
```

## greetings.swift
```swift
// Greetings.swift

import Foundation

struct Greetings {
    static let allGreetings = [
        "Say: \"Hello, I'm [your name]\"",
        "Di: \"Hola, soy [tu nombre]\"",
        "Dire: \"Bonjour, je suis [votre nom]\"",
        "Sag: \"Hallo, ich bin [dein Name]\"",
        "说: \"你好，我是[你的名字]\"",
        "Diga: \"Olá, eu sou [seu nome]\"",
        "Say: \"こんにちは、私は[あなたの名前]です\"",
        "Gul: \"Merhaba, ben [senin ismin]\""
    ]
}
```

## NameInputView.swift
```swift
import SwiftUI
import Combine

struct NameInputView: View {
    @Binding var userName: String
    @Binding var step: Int
    
    @StateObject private var inputNameService = InputNameService()
    @StateObject private var userProfile = UserProfileViewModel.shared
    @ObservedObject private var timelineState = TimelineState.shared
    
    // MARK: - State Variables
    @State private var receivedName: String = ""
    @State private var prosody: String = ""
    @State private var feeling: String = ""
    @State private var confidenceScore: Int = 0
    @State private var confidenceReasoning: String = ""
    @State private var psychoanalysis: String = ""
    @State private var locationBackground: String = ""
    
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isCorrectName: Bool = true
    @State private var confirmedName: String = ""
    @State private var isRecording: Bool = false
    @State private var isUploading: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showInstructions: Bool = false
    @State private var pulseOpacity: Bool = false
    @State private var typingText: String = ""
    @State private var currentTypingIndex: Int = 0
    @State private var waveformAnimation: Bool = false
    
    private let demoWaveform: [CGFloat] = [0.2, 0.5, 0.3, 0.7, 0.2, 0.6, 0.4, 0.8, 0.3, 0.6, 0.4]
    @State private var timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()
    
    @State private var circuitPhase: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            circuitBackground
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        circuitPhase = 1000
                    }
                }
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    
                    if !showConfirmation {
                        recordingSection
                    } else {
                        confirmationSection
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if isUploading {
                    uploadingOverlay
                }
                if showInstructions {
                    instructionsOverlay
                }
            }
        )
        .background(Color.black)
        .onAppear {
            startNewTypingAnimation()
            startAnimations()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - View Components
    private var circuitBackground: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 30
                
                for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                    for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gridSize, y: y))
                        }
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + gridSize))
                        }
                    }
                }
            }
            .stroke(Color(hex: "#00FF00").opacity(0.1), style: StrokeStyle(
                lineWidth: 1,
                lineCap: .round,
                lineJoin: .round,
                dashPhase: circuitPhase
            ))
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 25) {
            Text("Voice Identification")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
            
            Text(typingText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .onReceive(timer) { _ in
                    startNewTypingAnimation()
                }
            
            Button(action: { showInstructions.toggle() }) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("How to Record")
                }
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
            }
            
            waveformView
            
            recordButton
        }
    }
    
    private var waveformView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#00FF00").opacity(0.1))
                .blur(radius: 10)
                .scaleEffect(waveformAnimation ? 1.1 : 1.0)
            
            HStack(spacing: 6) {
                ForEach(demoWaveform.indices, id: \.self) { index in
                    Capsule()
                        .fill(isRecording ? Color(hex: "#00FF00") : Color(hex: "#00FF00").opacity(0.4))
                        .frame(width: 4, height: demoWaveform[index] * 60)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: isRecording
                        )
                }
            }
            .padding(.vertical, 30)
        }
        .frame(height: 120)
        .padding(.horizontal)
    }
    
    private var recordButton: some View {
        Button(action: handleRecordButton) {
            HStack {
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 24))
                    .symbolEffect(.bounce, value: isRecording)
                Text(isRecording ? "Listening..." : "Speak")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isRecording ? .black : Color(hex: "#00FF00"))
            .frame(width: 280, height: 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color(hex: "#00FF00") : Color.black)
                        .shadow(color: Color(hex: "#00FF00").opacity(isRecording ? 0.6 : 0.3), radius: 10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                        .blur(radius: 3)
                        .opacity(pulseOpacity ? 0.8 : 0.2)
                }
            )
        }
    }
    
    private var confirmationSection: some View {
        VStack(spacing: 30) {
            Text("I Heard...")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .opacity(0.8)
            
            Text(receivedName)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)
            
            VoiceAnalysisCard(response: ServerResponse(
                name: receivedName,
                prosody: prosody,
                feeling: feeling,
                confidence_score: confidenceScore,
                confidence_reasoning: confidenceReasoning,
                psychoanalysis: psychoanalysis,
                location_background: locationBackground
            ))
            .padding(.horizontal)
            
            VStack {
                Toggle(isOn: $isCorrectName) {
                    Text(isCorrectName ? "That's Me" : "Not Quite Right")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                }
                .toggleStyle(CyberpunkToggleStyle())
            }
            .padding(.horizontal, 40)
            
            if !isCorrectName {
                TextField("Tell me your name", text: $confirmedName)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                            .shadow(color: Color(hex: "#00FF00").opacity(0.3), radius: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .onAppear {
                        confirmedName = receivedName
                    }
            }
            
            HStack(spacing: 20) {
                Button(action: confirmName) {
                    Text("Continue >>")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 56)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#00FF00"))
                                    .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                                    .blur(radius: 3)
                            }
                        )
                }
                
                Button(action: retryRecording) {
                    Text("Retry")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                        .frame(width: 120, height: 56)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                            }
                        )
                }
            }
        }
    }
    
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00FF00")))
                    .scaleEffect(1.5)
                
                Text("Analyzing voice pattern...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
            }
        }
    }
    
    private var instructionsOverlay: some View {
        VStack(spacing: 20) {
            Text("How to Record")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            
            VStack(alignment: .leading, spacing: 15) {
                Text("1. Tap 'Speak' when ready.")
                Text("2. Clearly state your name.")
                Text("3. Speak naturally.")
                Text("4. Tap again when finished.")
                Text("5. Verify the analysis.")
            }
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            
            Button("Got It") {
                showInstructions = false
            }
            .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
        .padding()
        .foregroundColor(Color(hex: "#00FF00"))
        .background(Color.black.opacity(0.95))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(hex: "#00FF00"), lineWidth: 1)
        )
        .padding()
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseOpacity = true
        }
        
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waveformAnimation = true
        }
    }
    
    private func startNewTypingAnimation() {
        typingText = ""
        currentTypingIndex = 0
        let newPrompt = Greetings.allGreetings.randomElement() ?? "Say: \"Hello, I'm John Doe\""
        
        func typeNextCharacter() {
            guard currentTypingIndex < newPrompt.count else { return }
            
            typingText += String(newPrompt[newPrompt.index(newPrompt.startIndex, offsetBy: currentTypingIndex)])
            currentTypingIndex += 1
            
            if currentTypingIndex < newPrompt.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    typeNextCharacter()
                }
            }
        }
        
        typeNextCharacter()
    }
    
    private func handleRecordButton() {
        if isRecording {
            stopRecording()
            processAudioFile()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try inputNameService.startRecording()
            isRecording = true
            startAnimations()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func stopRecording() {
        isRecording = false
        inputNameService.stopRecording()
        pulseOpacity = false
    }
    
    private func processAudioFile() {
        isUploading = true
        
        Task {
            do {
                let response = try await inputNameService.uploadAudioFile()
                DispatchQueue.main.async {
                    updateUIWithResponse(response)
                }
            } catch {
                DispatchQueue.main.async {
                    handleError(error)
                }
            }
        }
    }
    
    private func updateUIWithResponse(_ response: ServerResponse) {
        receivedName = response.safeName
        prosody = response.safeProsody
        feeling = response.safeFeeling
        confidenceScore = response.safeConfidenceScore
        confidenceReasoning = response.safeConfidenceReasoning
        psychoanalysis = response.safePsychoanalysis
        locationBackground = response.safeLocationBackground
        showConfirmation = true
        isUploading = false
    }
    
    private func handleError(_ error: Error) {
        isUploading = false
        showError = true
        errorMessage = error.localizedDescription
    }
    
    private func confirmName() {
        let nameToSave = isCorrectName ? receivedName : confirmedName
        saveNameAndCreateMoment(nameToSave: nameToSave)
    }
    
    private func saveNameAndCreateMoment(nameToSave: String) {
        userProfile.saveUsername(nameToSave)
        userName = nameToSave
        
        // Create the initial moment from voice analysis
        timelineState.addInitialMoment(from: ServerResponse(
            name: nameToSave,
            prosody: prosody,
            feeling: feeling,
            confidence_score: confidenceScore,
            confidence_reasoning: confidenceReasoning,
            psychoanalysis: psychoanalysis,
            location_background: locationBackground
        ))
        
        // Move to the next step
        step += 1
    }
    
    private func retryRecording() {
        showConfirmation = false
        isRecording = false
        pulseOpacity = false
    }
}

// MARK: - Custom Styles
struct CyberpunkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color(hex: "#00FF00").opacity(0.3) : Color.black)
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    )
                
                Circle()
                    .fill(configuration.isOn ? Color(hex: "#00FF00") : Color(hex: "#00FF00").opacity(0.5))
                    .frame(width: 24, height: 24)
                    .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 5)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

#Preview {
    NameInputView(userName: .constant(""), step: .constant(0))
        .preferredColorScheme(.dark)
}
```

## TutorialView.swift
```swift
import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @State private var userName: String = ""
    @State private var currentStep: Int = 0
    @StateObject private var inputNameService = InputNameService()
    @State private var showWelcomeAnimation: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if currentStep == 0 {
                        NameInputView(userName: $userName, step: $currentStep)
                            .transition(.opacity)
                    } else {
                        welcomeView
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Skip") {
                withAnimation {
                    dismiss()
                }
            }
            .foregroundColor(.green))
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Text("Welcome")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .opacity(showWelcomeAnimation ? 1 : 0)
            
            Text(userName)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.green)
                .opacity(showWelcomeAnimation ? 1 : 0)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                Text("Begin Journey")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.5), radius: 10)
            }
            .opacity(showWelcomeAnimation ? 1 : 0)
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                showWelcomeAnimation = true
            }
        }
    }
}

#Preview {
    TutorialView()
}
```

## UploadingOverlay.swift
```swift
import SwiftUI

struct UploadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    .scaleEffect(1.5)
                
                Text("analyzing voice pattern...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    UploadingOverlay()
}
```

## MomentCard.swift
```swift
import SwiftUI

struct MomentCard: View {
    let moment: Moment
    @State private var showingActions = false
    
    private var icon: String {
        switch moment.category {
        case "voice_analysis": return "waveform.circle.fill"
        case "reflection": return "text.bubble.fill"
        case "achievement": return "star.fill"
        default: return "circle.fill"
        }
    }
    
    private var displayContent: [(String, String)] {
        if moment.category == "voice_analysis",
           let name = moment.metadata["name"] as? String,
           let prosody = moment.metadata["prosody"] as? String,
           let feeling = moment.metadata["feeling"] as? String,
           let analysis = moment.metadata["analysis"] as? String {
            return [
                ("Name", name),
                ("Prosody", prosody),
                ("Feeling", feeling),
                ("Analysis", analysis)
            ]
        }
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.purple)
                
                Text("Voice Analysis")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                Text(timeString(from: moment.timestamp))
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                
                Button(action: { showingActions = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.gray)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            // Content
            ForEach(displayContent, id: \.0) { label, content in
                VStack(alignment: .leading, spacing: 8) {
                    Text(label)
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                    Text(content)
                        .font(.system(size: 16))
                }
            }
            
            // Tags
            if !moment.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(moment.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // Footer
            HStack(spacing: 20) {
                Button(action: {}) {
                    Label("Like", systemImage: "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
                
                if (moment.interactions["shared"] as? Bool) == true {
                    Label("Shared", systemImage: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .confirmationDialog("Moment Actions", isPresented: $showingActions) {
            Button("Share", role: .none) {}
            Button("Delete", role: .destructive) {}
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MomentCard(moment: Moment.voiceAnalysis(
        name: "Alex Smith",
        prosody: "Confident and clear",
        feeling: "Energetic",
        confidenceScore: 85,
        analysis: "The voice shows confidence and enthusiasm",
        extraData: ["shared": true]
    ))
    .padding()
}
```

## CircuitBackground.swift
```swift
import SwiftUI

struct CircuitBackground: View {
    let circuitPhase: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 30
                
                for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                    for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gridSize, y: y))
                        }
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + gridSize))
                        }
                    }
                }
            }
            .stroke(Color.green.opacity(0.1), style: StrokeStyle(
                lineWidth: 1,
                lineCap: .round,
                lineJoin: .round,
                dashPhase: circuitPhase
            ))
        }
    }
}

#Preview {
    CircuitBackground(circuitPhase: 0)
        .preferredColorScheme(.dark)
}
```

## VoiceAnalysisCard.swift
```swift
import SwiftUI

struct VoiceAnalysisCard: View {
    let response: ServerResponse
    
    @State private var closedSections: Set<Section> = []
    
    enum Section: Hashable {
        case prosody, feeling, confidence, psychoanalysis, locationBackground
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Prosody Section
            AccordionSection(
                title: "Voice Pattern",
                systemImage: "waveform",
                isExpanded: !closedSections.contains(.prosody),
                onTap: { toggleSection(.prosody) }
            ) {
                Text(response.safeProsody)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Feeling Section
            AccordionSection(
                title: "Emotional Tone",
                systemImage: "heart.text.square",
                isExpanded: !closedSections.contains(.feeling),
                onTap: { toggleSection(.feeling) }
            ) {
                Text(response.safeFeeling)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Confidence Score Section
            AccordionSection(
                title: "Confidence Analysis",
                systemImage: "checkmark.seal.fill",
                isExpanded: !closedSections.contains(.confidence),
                onTap: { toggleSection(.confidence) }
            ) {
                VStack(spacing: 12) {
                    // Circular confidence score
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(response.safeConfidenceScore) / 100)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(response.safeConfidenceScore)")
                                .font(.system(size: 32, weight: .bold))
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Reasoning
                    Text(response.safeConfidenceReasoning)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Psychoanalysis Section
            AccordionSection(
                title: "Psychoanalysis",
                systemImage: "brain.head.profile",
                isExpanded: !closedSections.contains(.psychoanalysis),
                onTap: { toggleSection(.psychoanalysis) }
            ) {
                Text(response.safePsychoanalysis)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Location Background Section
            AccordionSection(
                title: "Location Background",
                systemImage: "location.fill",
                isExpanded: !closedSections.contains(.locationBackground),
                onTap: { toggleSection(.locationBackground) }
            ) {
                Text(response.safeLocationBackground)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func toggleSection(_ section: Section) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if closedSections.contains(section) {
                closedSections.remove(section)
            } else {
                closedSections.insert(section)
            }
        }
    }
}

struct AccordionSection<Content: View>: View {
    let title: String
    let systemImage: String
    let isExpanded: Bool
    let onTap: () -> Void
    let content: Content
    
    init(
        title: String,
        systemImage: String,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            
            if isExpanded {
                content
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// Preview provider with sample data
struct VoiceAnalysisCard_Previews: PreviewProvider {
    static let sampleResponse = ServerResponse(
        name: "Nicole Hayes",
        prosody: "Nicole pronounced her name with clear articulation but had a slightly hesitant tone, with a gentle rising inflection on the final syllable of 'Hayes'. This could indicate either a sense of uncertainty in this new context or a natural part of her speech pattern. She seemed to speak with a slightly formal tone, perhaps a sign of trying to maintain a professional and polite demeanor.",
        feeling: "Nicole seemed a little nervous or uncertain, possibly due to the newness of the interaction. Her voice had a slight rising intonation at the end of her name, suggesting a question or seeking validation.",
        confidence_score: 92,
        confidence_reasoning: "The user's pronunciation was clear with minimal background noise, but a slight accent introduced minor uncertainties in the transcription.",
        psychoanalysis: "The user's speech pattern shows signs of guardedness, as evidenced by a slower pace and occasional hesitation. This could indicate a cautious approach to self-expression, suggesting a reflective personality or possible concerns about judgment from others.",
        location_background: "The background noise suggests an indoor setting, possibly a quiet office or a home workspace. The absence of significant ambient sounds indicates a controlled environment conducive to clear communication."
    )
    
    static var previews: some View {
        VoiceAnalysisCard(response: sampleResponse)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
```

## VoiceRecordButton.swift
```swift
import SwiftUI

struct VoiceRecordButton: View {
    @Binding var isRecording: Bool
    let pulseOpacity: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 24))
                    .symbolEffect(.bounce, value: isRecording)
                Text(isRecording ? "listening..." : "speak")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isRecording ? .black : .green)
            .frame(width: 280, height: 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.green : Color.black)
                        .shadow(color: Color.green.opacity(isRecording ? 0.6 : 0.3), radius: 10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 1)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        .blur(radius: 3)
                        .opacity(pulseOpacity ? 0.8 : 0.2)
                }
            )
        }
    }
}

#Preview {
    VoiceRecordButton(isRecording: .constant(false), pulseOpacity: true) {
        print("Record button tapped")
    }
}
```

## SplashView.swift
```swift
import SwiftUI
import GoogleSignInSwift

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var isShowingSignIn = false
    @State private var isShowingTutorial = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Welcome to Caring")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your personal care companion")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            GoogleSignInButton(action: viewModel.signInWithGoogle)
                .frame(maxWidth: .infinity, minHeight: 55)
                .padding(.horizontal)
            
            Button(action: {
                isShowingTutorial = true
            }) {
                Text("Start Tutorial")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $isShowingTutorial) {
            TutorialView()
        }
        .sheet(isPresented: $isShowingSignIn) {
            SignInView()
        }
    }
}

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                GoogleSignInButton(action: viewModel.signInWithGoogle)
                    .frame(maxWidth: .infinity, minHeight: 55)
                    .padding()
            }
            .navigationTitle("Sign In")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    AuthenticationView()
}
```

## LaunchView.swift
```swift
import SwiftUI

struct LaunchView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @AppStorage("isSignedIn") private var isSignedIn = false
    
    var body: some View {
        if isActive {
            if isSignedIn {
                ContentView()
            } else {
                AuthenticationView()
            }
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.90, green: 0.90, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Text("CaringMind")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.4, blue: 0.8),
                                    Color(red: 0.3, green: 0.3, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(2)
                    
                    Text("Your Digital Wellness Companion")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
                        .padding(.top, -15)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.4, blue: 0.8)))
                        .scaleEffect(1.2)
                        .padding(.top, 10)
                }
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.7)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchView()
}
```

## ContentView.swift
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var timelineState = TimelineState.shared
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
                .tabItem {
                    Label(Tab.explore.title, systemImage: Tab.explore.icon)
                }
                .tag(Tab.explore)
            
            SpeechRecognitionView()
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
```

## InputNameService.swift
```swift
import Foundation
import AVFoundation

// MARK: - Protocols
protocol AudioRecordingService {
    var isRecording: Bool { get }
    func startRecording() throws
    func stopRecording()
    func getRecordedAudioURL() -> URL?
}

protocol AudioUploadService {
    func uploadAudio(from url: URL) async throws -> ServerResponse
}

protocol InputNameServiceProtocol: AudioRecordingService, AudioUploadService {
    var showError: Bool { get set }
    var errorMessage: String? { get set }
}

// MARK: - Error Types
enum AudioRecordingError: LocalizedError {
    case failedToCreateFileURL
    case recordingSetupFailed(Error)
    case noRecordingFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateFileURL:
            return "Failed to create audio file URL"
        case .recordingSetupFailed(let error):
            return "Recording setup failed: \(error.localizedDescription)"
        case .noRecordingFound:
            return "No recording found"
        }
    }
}

// MARK: - Main Service Implementation
class InputNameService: NSObject, InputNameServiceProtocol, ObservableObject {
    @Published var isRecording = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let backendURL: URL
    private let audioSession: AVAudioSession
    
    init(backendURL: URL = URL(string: "https://9419-2a01-4ff-f0-b1f6-00-1.ngrok-free.app/onboarding/v3/process-audio")!,
         audioSession: AVAudioSession = .sharedInstance()) {
        self.backendURL = backendURL
        self.audioSession = audioSession
        super.init()
    }
    
    // MARK: - AudioRecordingService Implementation
    func startRecording() throws {
        do {
            try setupAudioSession()
            try setupAndStartRecorder()
            isRecording = true
        } catch {
            throw AudioRecordingError.recordingSetupFailed(error)
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func getRecordedAudioURL() -> URL? {
        return audioFileURL
    }
    
    // MARK: - AudioUploadService Implementation
    func uploadAudio(from url: URL) async throws -> ServerResponse {
        var request = try createUploadRequest(for: url)
        return try await performUpload(with: request)
    }
    
    // For backward compatibility
    func uploadAudioFile() async throws -> ServerResponse {
        guard let fileURL = audioFileURL else {
            throw AudioRecordingError.noRecordingFound
        }
        return try await uploadAudio(from: fileURL)
    }
}

// MARK: - AVAudioRecorderDelegate
extension InputNameService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            showError = true
            errorMessage = "Recording failed to complete successfully"
        }
    }
}

// MARK: - Private Helper Methods
private extension InputNameService {
    func setupAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }
    
    func setupAndStartRecorder() throws {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recordedAudio_\(UUID().uuidString).wav"
        audioFileURL = documents.appendingPathComponent(fileName)
        
        guard let fileURL = audioFileURL else {
            throw AudioRecordingError.failedToCreateFileURL
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }
    
    func createUploadRequest(for fileURL: URL) throws -> URLRequest {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        let audioData = try Data(contentsOf: fileURL)
        data.append(audioData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        return request
    }
    
    func performUpload(with request: URLRequest) async throws -> ServerResponse {
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(ServerResponse.self, from: responseData)
    }
}
```

## AppSettings.swift
```swift
//
//  AppSettings.swift
//  caring
//
//  Created by Elijah Arbee on 12/8/24.
//


import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard
    
    enum Keys {
        static let darkMode = "darkModeEnabled"
        static let notifications = "notificationsEnabled"
        static let sound = "soundEnabled"
        // permissions
        static let devMode = "devModeEnabled"
    }
    
    @Published var isPresented = false
    @Published var darkModeEnabled: Bool {
        didSet {
            defaults.set(darkModeEnabled, forKey: Keys.darkMode)
            defaults.synchronize()
            withAnimation(.easeInOut(duration: 0.2)) {
                objectWillChange.send()
            }
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notifications)
            defaults.synchronize()
        }
    }
    
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.sound)
            defaults.synchronize()
        }
    }
    
    @Published var devModeEnabled: Bool {
        didSet {
            defaults.set(devModeEnabled, forKey: Keys.devMode)
            defaults.synchronize()
        }
    }
    
    @Published var showTutorial = false
    
    private init() {
        self.darkModeEnabled = defaults.bool(forKey: Keys.darkMode)
        self.notificationsEnabled = defaults.bool(forKey: Keys.notifications)
        self.soundEnabled = defaults.bool(forKey: Keys.sound)
        self.devModeEnabled = defaults.bool(forKey: Keys.devMode)
    }
}
```

## TruthGameLogic.swift
```swift
// TruthGameLogic.swift **DO NOT OMIT ANYTHING FROM THE FOLLOWING CONTENT, INCLUDING & NOT LIMITED TO COMMENTED NOTES
import SwiftUI
import Combine
import AVFoundation
import SwiftyJSON

// MARK: 1. Data Models

/// 1.1. Represents the analysis of an individual statement.
struct StatementAnalysis: Identifiable, Decodable {
    let id = UUID()
    let statement: String // Mapped from 'text' in JSON
    let isTruth: Bool
    let pitchVariation: String
    let pauseDuration: Double
    let stressLevel: String
    let confidenceScore: Double

    // Mapping JSON keys to struct properties
    enum CodingKeys: String, CodingKey {
        case statement = "text"
        case isTruth
        case pitchVariation
        case pauseDuration
        case stressLevel
        case confidenceScore
    }
}

/// 1.2. Represents the overall analysis response containing multiple statements.
struct AnalysisResponse: Decodable {
    let finalConfidenceScore: Double
    let guessJustification: String
    let responseMessage: String
    let statements: [StatementAnalysis]
}

/// 1.3. Queue Data Structure for StatementAnalysis
public struct Queue<T> {
    fileprivate var array = [T?]()
    fileprivate var head = 0

    public var isEmpty: Bool {
        return count == 0
    }

    public var count: Int {
        return array.count - head
    }

    public mutating func enqueue(_ element: T) {
        array.append(element)
    }

    public mutating func dequeue() -> T? {
        guard head < array.count, let element = array[head] else { return nil }

        array[head] = nil
        head += 1

        let percentage = Double(head) / Double(array.count)
        if array.count > 50 && percentage > 0.25 {
            array.removeFirst(head)
            head = 0
        }

        return element
    }

    public var front: T? {
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
}

// MARK: 2. Error Wrapper

/// 2.1. A simple wrapper to make error messages identifiable.
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: 3. Service Class

/// 3.1. Manages the analysis data, business logic, and audio recording.
class AnalysisService: NSObject, ObservableObject {
    // 3.2. Published properties to notify the UI of data changes.
    @Published var response: AnalysisResponse?
    @Published var statements: [StatementAnalysis] = []
    @Published var swipedStatements: Set<UUID> = [] // Tracks swiped statements by their IDs
    @Published var showSummary: Bool = false
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var recordedURL: URL?
    @Published var recordingError: ErrorWrapper?

    private var cancellables = Set<AnyCancellable>()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    // 3.3. Queue for managing statement cards
    private var statementQueue = Queue<StatementAnalysis>()

    // MARK: 4. Initialization

    /// 4.1. Initializes the service and requests microphone access.
    override init() {
        super.init()
        requestMicrophoneAccess()
    }

    // MARK: 5. Microphone Access

    /// 5.1. Requests permission to access the microphone.
    private func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.recordingError = ErrorWrapper(message: "Microphone access is required to record statements.")
                }
            }
        }
    }

    // MARK: 6. Recording Functions

    /// 6.1. Starts recording audio in WAV format.
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [])
            try recordingSession.setActive(true)

            // Updated settings for WAV format
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]

            let filename = getDocumentsDirectory().appendingPathComponent("recorded_statement.wav") // Updated to .wav
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            DispatchQueue.main.async {
                self.isRecording = true
                self.recordedURL = filename
            }
        } catch {
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to start recording: \(error.localizedDescription)")
            }
        }
    }

    /// 6.2. Stops recording audio.
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    /// 6.3. Plays the recorded audio.
    func playRecording() {
        guard let url = recordedURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to play recording: \(error.localizedDescription)")
            }
        }
    }

    /// 6.4. Stops playing audio.
    func stopPlaying() {
        audioPlayer?.stop()
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    // MARK: 7. Upload Function

    /// 7.1. Uploads the recorded audio to the backend for analysis.
    func uploadRecording() {
        guard let url = recordedURL else {
            print("Log: No recording found. Aborting upload.")
            self.recordingError = ErrorWrapper(message: "No recording found to upload.")
            return
        }

        // Corrected to original upload URL
        guard let uploadURL = URL(string: "https://8bdb-2a09-bac5-661b-1232-00-1d0-c6.ngrok-free.app/TruthNLie") else {
            print("Log: Invalid upload URL.")
            self.recordingError = ErrorWrapper(message: "Invalid upload URL.")
            return
        }

        print("Log: Starting upload for file: \(url.lastPathComponent)")

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = url.lastPathComponent
        let mimeType = "audio/wav" // Updated MIME type for WAV

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")

        if let fileData = try? Data(contentsOf: url) {
            body.append(fileData)
            print("Log: File data appended successfully for \(filename)")
        } else {
            print("Log: Failed to read the recorded file at \(url.absoluteString)")
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to read the recorded file.")
            }
            return
        }
        body.append("\r\n--\(boundary)--\r\n")

        // Create a URLSession upload task
        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Log: Upload failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "Upload failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                print("Log: No data received from server.")
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "No data received from server.")
                }
                return
            }

            print("Log: Response data received, proceeding with JSON parsing.")

            do {
                let json = try JSON(data: data)
                if let serverError = json["error"].string {
                    print("Log: Server Error - \(serverError)")
                    DispatchQueue.main.async {
                        self.recordingError = ErrorWrapper(message: "Server Error: \(serverError)")
                    }
                    return
                }

                let finalConfidenceScore = json["finalConfidenceScore"].doubleValue
                let guessJustification = json["guessJustification"].stringValue
                let responseMessage = json["responseMessage"].stringValue
                print("Log: Parsed final confidence score: \(finalConfidenceScore)")

                var statementsArray: [StatementAnalysis] = []
                for statementJSON in json["statements"].arrayValue {
                    let statement = StatementAnalysis(
                        statement: statementJSON["text"].stringValue,
                        isTruth: statementJSON["isTruth"].boolValue,
                        pitchVariation: statementJSON["pitchVariation"].stringValue,
                        pauseDuration: statementJSON["pauseDuration"].doubleValue,
                        stressLevel: statementJSON["stressLevel"].stringValue,
                        confidenceScore: statementJSON["confidenceScore"].doubleValue
                    )
                    statementsArray.append(statement)
                    print("Log: Added statement to array: \(statement.statement) with confidence score \(statement.confidenceScore)")
                }

                let analysisResponse = AnalysisResponse(
                    finalConfidenceScore: finalConfidenceScore,
                    guessJustification: guessJustification,
                    responseMessage: responseMessage,
                    statements: statementsArray
                )

                DispatchQueue.main.async {
                    self.response = analysisResponse
                    print(analysisResponse)
                    print("Log: Analysis response successfully set. Invoking setupStatements()")
                    self.setupStatements()
                }
            } catch {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Log: Failed to decode JSON response: \(jsonString)")
                }
                print("Log: Decoding error: \(error)")
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "Failed to parse response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: 8. Setup Functions

    /// 8.1. Sets up the statements queue based on the analysis response.
    func setupStatements() {
        guard let response = response else {
            print("Log: No response found, cannot setup statements.")
            return
        }

        print("Log: Setting up statements queue from response data.")

        statementQueue = Queue<StatementAnalysis>()
        statements = []
        swipedStatements = []

        if let lieStatement = response.statements.first(where: { !$0.isTruth }) {
            statementQueue.enqueue(lieStatement)
            print("Log: Lie statement enqueued: \(lieStatement.statement)")
        }

        for statement in response.statements where statement.isTruth {
            statementQueue.enqueue(statement)
            print("Log: True statement enqueued: \(statement.statement)")
        }

        print("Log: Statements setup complete. Loading next statement.")
        loadNextStatement()
    }


    // MARK: 9. Swipe Handling

    /// 9.1. Handles the swipe action by updating the swipedStatements set.
    /// - Parameters:
    ///   - direction: The direction in which the card was swiped.
    ///   - statement: The specific statement that was swiped.
    func handleSwipe(direction: SwipeDirection, for statement: StatementAnalysis) {
        // Add the swiped statement's ID to the swipedStatements set.
        swipedStatements.insert(statement.id)

        // Load the next statement from the queue
        loadNextStatement()
    }

    // MARK: 10. Queue Management Functions

    /// 10.1. Loads the next statement from the queue into the statements array for display.
    private func loadNextStatement() {
        if let nextStatement = statementQueue.dequeue() {
            // Replace the current statement with the next one
            statements = [nextStatement]
        } else {
            // No more statements, show summary
            DispatchQueue.main.async {
                withAnimation {
                    self.showSummary = true
                }
            }
        }
    }

    /// 10.2. Resets the statements queue and related properties.
    func resetSwipes() {
        withAnimation {
            swipedStatements.removeAll()
            showSummary = false
            response = nil
            statements.removeAll()
            recordedURL = nil
            statementQueue = Queue<StatementAnalysis>() // Reset the queue
        }
    }

    // MARK: 11. Helper Functions

    /// 11.1. Retrieves the documents directory URL.
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: 12. Swipe Direction Enum

    /// 12.1. Enum to represent swipe directions.
    enum SwipeDirection {
        case left, right
    }
}

// MARK: 13. AVAudioRecorder Delegate

extension AnalysisService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingError = ErrorWrapper(message: "Recording was not successful.")
        }
    }
}

// MARK: 14. AVAudioPlayer Delegate

extension AnalysisService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

// MARK: 15. Data Extension for Multipart Form Data

extension Data {
    /// Appends a string to the Data.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

```

## AuthenticationService.swift
```swift
import Foundation
import GoogleSignIn
import GoogleSignInSwift

// Protocol for authentication service
protocol AuthenticationServiceProtocol {
    func signInWithGoogle() async throws -> User
    func signOut() async throws
    var currentUser: User? { get }
}

// User model that's independent of the authentication provider
struct User: Codable {
    let id: String
    let email: String?
    let name: String?
    let photoURL: URL?
}

// Google Authentication Implementation
class GoogleAuthService: AuthenticationServiceProtocol {
    static let shared = GoogleAuthService()
    private var currentGoogleUser: GIDGoogleUser?
    
    var currentUser: User? {
        guard let googleUser = currentGoogleUser else { return nil }
        return User(
            id: googleUser.userID ?? "",
            email: googleUser.profile?.email,
            name: googleUser.profile?.name,
            photoURL: googleUser.profile?.imageURL(withDimension: 100)
        )
    }
    
    func signInWithGoogle() async throws -> User {
        guard let topVC = await UIApplication.shared.topViewController() else {
            throw AuthError.presentationError
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        self.currentGoogleUser = gidSignInResult.user
        
        guard let user = self.currentUser else {
            throw AuthError.invalidUser
        }
        
        return user
    }
    
    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        self.currentGoogleUser = nil
    }
}

// Custom errors
enum AuthError: Error {
    case invalidUser
    case presentationError
    case unknown
}

// Helper extension to get top view controller
extension UIApplication {
    func topViewController() async -> UIViewController? {
        let scenes = await self.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.rootViewController?.topViewController()
    }
}

extension UIViewController {
    func topViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topViewController() ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topViewController() ?? tab
        }
        return self
    }
}
```

## SpeechRecognitionMetadata.swift
```swift
import Speech

struct TranscriptionSegment: Equatable {
    var alternativeSubstrings: [String]
    var confidence: Float
    var duration: TimeInterval
    var substring: String
    var timestamp: TimeInterval
    
    init(_ transcriptionSegment: SFTranscriptionSegment) {
        self.alternativeSubstrings = transcriptionSegment.alternativeSubstrings
        self.confidence = transcriptionSegment.confidence
        self.duration = transcriptionSegment.duration
        self.substring = transcriptionSegment.substring
        self.timestamp = transcriptionSegment.timestamp
    }
}

struct Transcription: Equatable {
    var formattedString: String
    var segments: [TranscriptionSegment]
    
    init(_ transcription: SFTranscription) {
        self.formattedString = transcription.formattedString
        self.segments = transcription.segments.map(TranscriptionSegment.init)
    }
}

struct AcousticFeature: Equatable {
    var acousticFeatureValuePerFrame: [Double]
    var frameDuration: TimeInterval
    
    init(_ acousticFeature: SFAcousticFeature) {
        self.acousticFeatureValuePerFrame = acousticFeature.acousticFeatureValuePerFrame
        self.frameDuration = acousticFeature.frameDuration
    }
}

struct VoiceAnalytics: Equatable {
    var jitter: AcousticFeature
    var pitch: AcousticFeature
    var shimmer: AcousticFeature
    var voicing: AcousticFeature
    
    init(_ voiceAnalytics: SFVoiceAnalytics) {
        self.jitter = AcousticFeature(voiceAnalytics.jitter)
        self.pitch = AcousticFeature(voiceAnalytics.pitch)
        self.shimmer = AcousticFeature(voiceAnalytics.shimmer)
        self.voicing = AcousticFeature(voiceAnalytics.voicing)
    }
}

struct SpeechRecognitionResult: Equatable {
    var bestTranscription: Transcription
    var isFinal: Bool
    var speechRecognitionMetadata: SpeechRecognitionMetadata?
    var transcriptions: [Transcription]
    
    init(_ speechRecognitionResult: SFSpeechRecognitionResult) {
        self.bestTranscription = Transcription(speechRecognitionResult.bestTranscription)
        self.isFinal = speechRecognitionResult.isFinal
        self.speechRecognitionMetadata = speechRecognitionResult.speechRecognitionMetadata.map(SpeechRecognitionMetadata.init)
        self.transcriptions = speechRecognitionResult.transcriptions.map(Transcription.init)
    }
}

struct SpeechRecognitionMetadata: Equatable {
    var averagePauseDuration: TimeInterval
    var speakingRate: Double
    var voiceAnalytics: VoiceAnalytics?
    
    init(_ speechRecognitionMetadata: SFSpeechRecognitionMetadata) {
        self.averagePauseDuration = speechRecognitionMetadata.averagePauseDuration
        self.speakingRate = speechRecognitionMetadata.speakingRate
        self.voiceAnalytics = speechRecognitionMetadata.voiceAnalytics.map(VoiceAnalytics.init)
    }
}
```

## SpeechRecognitionManager.swift
```swift
import AVFoundation
import Speech
import SwiftUI

class SpeechRecognitionManager: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var error: Error?
    @Published var metadata: SpeechRecognitionMetadata?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    @MainActor
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Reset state
        transcribedText = ""
        metadata = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Initialize audio engine if needed
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechRecognitionError.audioEngineError
        }
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionError
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        guard let speechRecognizer = speechRecognizer else {
            throw SpeechRecognitionError.recognizerError
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.error = error
                    self.stopRecording()
                    return
                }
                
                if let result = result {
                    let recognitionResult = SpeechRecognitionResult(result)
                    self.transcribedText = recognitionResult.bestTranscription.formattedString
                    if let sfMetadata = result.speechRecognitionMetadata {
                        print("Received metadata - Speaking rate: \(sfMetadata.speakingRate)")
                        self.metadata = SpeechRecognitionMetadata(sfMetadata)
                    }
                }
            }
        }
        
        isRecording = true
    }
    
    @MainActor
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Reset components but preserve metadata
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
    }
    
    enum SpeechRecognitionError: Error {
        case audioEngineError
        case recognizerError
        case audioSessionError
        case recognitionError
    }
    
    deinit {
        Task { @MainActor in
            stopRecording()
        }
    }
}

extension SpeechRecognitionManager {
    static var preview: SpeechRecognitionManager {
        let manager = SpeechRecognitionManager()
        manager.transcribedText = "This is a preview of transcribed text..."
        return manager
    }
}
```

## SpeechRecognitionView.swift
```swift
import SwiftUI
import Speech

struct SpeechRecognitionView: View {
    @StateObject private var manager = SpeechRecognitionManager()
    @State private var showAlert = false
    
    private let readMe = """
    This application demonstrates speech recognition capabilities. \
    It uses the Speech framework to perform live transcription of audio \
    to text with voice analytics.
    """
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(readMe)
                        .padding(.bottom, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(manager.transcribedText)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let metadata = manager.metadata {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Voice Analytics:")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Speaking Rate: \(metadata.speakingRate * 0.6, specifier: "%.1f") words/min")
                                Text("Average Pause Duration: \(metadata.averagePauseDuration, specifier: "%.2f")s")
                            }
                            .foregroundColor(.primary)
                            
                            if let analytics = metadata.voiceAnalytics {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Acoustic Features:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.top, 5)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        if !analytics.pitch.acousticFeatureValuePerFrame.isEmpty {
                                            HStack {
                                                Text("Pitch:")
                                                Text("\(analytics.pitch.acousticFeatureValuePerFrame.average(), specifier: "%.1f") Hz")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if !analytics.jitter.acousticFeatureValuePerFrame.isEmpty {
                                            HStack {
                                                Text("Jitter:")
                                                Text("\(analytics.jitter.acousticFeatureValuePerFrame.average(), specifier: "%.3f")")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if !analytics.shimmer.acousticFeatureValuePerFrame.isEmpty {
                                            HStack {
                                                Text("Shimmer:")
                                                Text("\(analytics.shimmer.acousticFeatureValuePerFrame.average(), specifier: "%.3f")")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if !analytics.voicing.acousticFeatureValuePerFrame.isEmpty {
                                            HStack {
                                                Text("Voicing:")
                                                Text("\(analytics.voicing.acousticFeatureValuePerFrame.average(), specifier: "%.1f")%")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Button {
                Task {
                    if manager.isRecording {
                        await manager.stopRecording()
                    } else {
                        do {
                            let status = await manager.requestAuthorization()
                            switch status {
                            case .authorized:
                                try await manager.startRecording()
                            case .denied:
                                showAlert = true
                            case .restricted:
                                showAlert = true
                            case .notDetermined:
                                break
                            @unknown default:
                                break
                            }
                        } catch {
                            showAlert = true
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: manager.isRecording ? "stop.circle.fill" : "arrowtriangle.right.circle.fill")
                        .font(.title)
                    Text(manager.isRecording ? "Stop Recording" : "Start Recording")
                }
                .foregroundColor(.white)
                .padding()
                .background(manager.isRecording ? Color.red : .green)
                .cornerRadius(16)
            }
            .padding(.bottom)
        }
        .alert("Speech Recognition Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .denied = manager.error as? SFSpeechRecognizerAuthorizationStatus {
                Text("You denied access to speech recognition. This app needs access to transcribe your speech.")
            } else if case .restricted = manager.error as? SFSpeechRecognizerAuthorizationStatus {
                Text("Your device does not allow speech recognition.")
            } else {
                Text("An error occurred while transcribing. Please try again.")
            }
        }
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

#Preview {
    SpeechRecognitionView()
}
```

## caringTests.swift
```swift
//
//  caringTests.swift
//  caringTests
//
//  Created by Elijah Arbee on 12/1/24.
//

import Testing

struct caringTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
```

## caringUITests.swift
```swift
//
//  caringUITests.swift
//  caringUITests
//
//  Created by Elijah Arbee on 12/1/24.
//

import XCTest

final class caringUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
```

## caringUITestsLaunchTests.swift
```swift
//
//  caringUITestsLaunchTests.swift
//  caringUITests
//
//  Created by Elijah Arbee on 12/1/24.
//

import XCTest

final class caringUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "LaunchScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

## Statistics

* Total Swift files listed: 36
