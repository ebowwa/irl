import SwiftUI
import Combine

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var moments: [Moment] = []
    @Published var searchText: String = ""
    
    private let userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredMoments: [Moment] {
        if searchText.isEmpty {
            return moments
        } else {
            return moments.filter { moment in
                let metadataString = moment.metadata.description.lowercased()
                let tagsString = moment.tags.joined(separator: " ").lowercased()
                return metadataString.contains(searchText.lowercased()) ||
                       tagsString.contains(searchText.lowercased())
            }
        }
    }
    
    init() {
        setupBindings()
        loadMoments()
        setupNotifications()
    }
    
    private func setupBindings() {
        // Bind to UserManager's timelineMoments
        userManager.$timelineMoments
            .receive(on: RunLoop.main)
            .assign(to: \.moments, on: self)
            .store(in: &cancellables)
    }
    
    private func loadMoments() {
        moments = userManager.timelineMoments
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .timelineUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadMoments()
            }
            .store(in: &cancellables)
    }
    
    func deleteMoment(_ moment: Moment) {
        // TODO: Implement moment deletion logic
    }
    
    func shareMoment(_ moment: Moment) {
        // TODO: Implement moment sharing logic
    }
}
