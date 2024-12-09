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
    @Published var transcriptionText: String = ""
    @Published var isTranscribing: Bool = false
    
    // Computed properties for tab-specific states
    var isRecordingEnabled: Bool {
        selectedTab == .record
    }
    
    // Tab selection handling
    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func startTranscription() {
        isTranscribing = true
        // Initialize speech recognition here
    }
    
    func stopTranscription() {
        isTranscribing = false
        // Stop speech recognition here
    }
    
    func updateTranscription(_ text: String) {
        transcriptionText = text
    }
}
