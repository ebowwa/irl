import SwiftUI
// TODO: say your friend is learning and add other relevant context to passover till the ai learns and has things to share
// Then the view should have updates that can be scrolled by the user and marked as viewed but still saved and locally hold off on saving now but keep the strings defined and easy to work with going forward. 
struct HomeView: View {
    @Binding var showSettings: Bool
    @State private var selectedTab: Tab = .insights

    enum Tab {
        case insights, trends
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                tabView
                
                contentView
                
                footerView
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello, User")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Here's your AI companion summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var tabView: some View {
        HStack(spacing: 0) {
            tabButton(title: "Insights", systemImage: "lightbulb.fill", tab: .insights)
            tabButton(title: "Trends", systemImage: "chart.line.uptrend.xyaxis", tab: .trends)
        }
        .padding(.top)
    }
    
    private func tabButton(title: String, systemImage: String, tab: Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .insights:
                    insightsView
                case .trends:
                    trendsView
                }
            }
            .padding()
        }
    }
    
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Insights")
                .font(.headline)
            
            ForEach(1...3, id: \.self) { _ in
                insightCard
            }
        }
    }
    
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Key Insight")
                    .font(.headline)
            }
            Text("This is where a brief description of the AI-generated insight would appear, highlighting important information for the user.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var trendsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Trends")
                .font(.headline)
            
            ForEach(1...2, id: \.self) { _ in
                trendCard
            }
        }
    }
    
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Trend Analysis")
                    .font(.headline)
            }
            Text("This area would display a chart or graph showing the user's progress or trends over time, as analyzed by the AI companion.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var footerView: some View {
        HStack {
            Image(systemName: "cpu")
            Text("AI Companion is always learning")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
    }
}

