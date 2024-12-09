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
