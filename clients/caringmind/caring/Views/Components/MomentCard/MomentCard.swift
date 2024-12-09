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
