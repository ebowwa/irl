import SwiftUI
import GoogleSignInSwift

struct AuthenticationSplashView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var isShowingTutorial = false
    @ObservedObject private var userManager = UserManager.shared
    
    var body: some View {
        Group {
            if userManager.isAuthenticated {
                ContentView()
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Welcome to Caring")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your personal care companion")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    GoogleSignInButton(action: viewModel.signInWithGoogle)
                        .frame(maxWidth: .infinity, minHeight: 55)
                        .padding(.horizontal)
                    
                    Button(action: {
                        isShowingTutorial = true
                    }) {
                        Text("Start Tutorial")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .fullScreenCover(isPresented: $isShowingTutorial) {
                    TutorialView()
                }
            }
        }
    }
}

#Preview {
    AuthenticationSplashView()
}
