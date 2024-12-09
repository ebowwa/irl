import SwiftUI

struct VoiceRecordButton: View {
    @Binding var isRecording: Bool
    let pulseOpacity: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 24))
                    .symbolEffect(.bounce, value: isRecording)
                Text(isRecording ? "listening..." : "speak")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isRecording ? .black : .green)
            .frame(width: 280, height: 56)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.green : Color.black)
                        .shadow(color: Color.green.opacity(isRecording ? 0.6 : 0.3), radius: 10)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 1)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                        .blur(radius: 3)
                        .opacity(pulseOpacity ? 0.8 : 0.2)
                }
            )
        }
    }
}

#Preview {
    VoiceRecordButton(isRecording: .constant(false), pulseOpacity: true) {
        print("Record button tapped")
    }
}
