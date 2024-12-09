import SwiftUI

struct UploadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    .scaleEffect(1.5)
                
                Text("analyzing voice pattern...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    UploadingOverlay()
}
