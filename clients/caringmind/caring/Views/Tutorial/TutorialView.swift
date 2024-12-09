import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @State private var userName: String = ""
    @State private var currentStep: Int = 0
    @StateObject private var inputNameService = InputNameService()
    @State private var showWelcomeAnimation: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if currentStep == 0 {
                        NameInputView(userName: $userName, step: $currentStep)
                            .transition(.opacity)
                    } else {
                        welcomeView
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Skip") {
                withAnimation {
                    dismiss()
                }
            }
            .foregroundColor(.green))
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Text("Welcome")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .opacity(showWelcomeAnimation ? 1 : 0)
            
            Text(userName)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.green)
                .opacity(showWelcomeAnimation ? 1 : 0)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    dismiss()
                }
            }) {
                Text("Begin Journey")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.green)
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.5), radius: 10)
            }
            .opacity(showWelcomeAnimation ? 1 : 0)
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                showWelcomeAnimation = true
            }
        }
    }
}

#Preview {
    TutorialView()
}
