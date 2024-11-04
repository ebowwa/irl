import SwiftUI

struct VoiceAnalysisCard: View {
    let prosody: String
    let feeling: String
    @State private var isProsodyShowing = false
    @State private var isFeelingShowing = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Prosody Section
            VStack(alignment: .leading, spacing: 8) {
                Label("Voice Pattern", systemImage: "waveform")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(prosody)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(isProsodyShowing ? 1.0 : 0.5)
            .opacity(isProsodyShowing ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isProsodyShowing)
            
            Divider()
                .opacity(isProsodyShowing ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: isProsodyShowing)
            
            // Feeling Section
            VStack(alignment: .leading, spacing: 8) {
                Label("Emotional Tone", systemImage: "heart.text.square")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(feeling)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(isFeelingShowing ? 1.0 : 0.5)
            .opacity(isFeelingShowing ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFeelingShowing)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .onAppear {
            // Trigger animations in sequence
            withAnimation(.easeIn(duration: 0.1)) {
                isProsodyShowing = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.1)) {
                    isFeelingShowing = true
                }
            }
        }
    }
}

// Preview
struct VoiceAnalysisCard_Previews: PreviewProvider {
    static let sampleResponse = ServerResponse(
        name: "Nicole Hayes",
        prosody: "Nicole pronounced her name with clear articulation but had a slightly hesitant tone, with a gentle rising inflection on the final syllable of 'Hayes'. This could indicate either a sense of uncertainty in this new context or a natural part of her speech pattern. She seemed to speak with a slightly formal tone, perhaps a sign of trying to maintain a professional and polite demeanor.",
        feeling: "Nicole seemed a little nervous or uncertain, possibly due to the newness of the interaction. Her voice had a slight rising intonation at the end of her name, suggesting a question or seeking validation."
    )
    
    static var previews: some View {
        VoiceAnalysisCard(
            prosody: sampleResponse.prosody,
            feeling: sampleResponse.feeling
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
