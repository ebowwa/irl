import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredMoments) { moment in
                    MomentCard(moment: moment)
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search moments...")
            .navigationTitle("Timeline")
            .onReceive(NotificationCenter.default.publisher(for: .timelineUpdated)) { _ in
                // This will trigger a view update when the timeline changes
            }
        }
    }
}

#Preview {
    TimelineView()
}
