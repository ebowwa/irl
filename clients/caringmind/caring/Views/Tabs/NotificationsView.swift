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
