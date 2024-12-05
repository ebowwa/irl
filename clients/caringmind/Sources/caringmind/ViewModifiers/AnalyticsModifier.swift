import SwiftUI

struct AnalyticsModifier: ViewModifier {
    let screenName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.logScreen(name: screenName)
            }
    }
}

extension View {
    func analyticsScreen(_ screenName: String) -> some View {
        modifier(AnalyticsModifier(screenName: screenName))
    }
}
