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
