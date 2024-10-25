import SwiftUI

@main
struct IRLApp: App {
    // Initialize shared state objects here
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    
    var body: some Scene {
        WindowGroup {
            EntryJourneyView()
                .environmentObject(globalState)
                .environmentObject(audioState)
        }
    }
}
