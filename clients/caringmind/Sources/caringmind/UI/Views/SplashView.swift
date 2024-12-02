//
//  SplashView.swift
//  CaringMind
//
//  Created by Elijah Arbee on 10/30/24.
//
import SwiftUI
#if os(iOS)
import UIKit
import GoogleSignIn
#endif
import GoogleSignInSwift
import ReSwift

struct SplashView: View {
    @State private var state = AppState.initialState()
    @State private var animate = false
    @State private var pulseOpacity = false
    @State private var showWelcome = false
    @State private var showButtons = false

    private let store = mainStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<20) { index in
                        Path { path in
                            let x = CGFloat.random(in: 0...geometry.size.width)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + 50, y: geometry.size.height))
                        }
                        .stroke(Color(hex: "#00FF00").opacity(0.1), lineWidth: 1)
                        .offset(x: animate ? 50 : -50)
                        .animation(
                            Animation.linear(duration: Double.random(in: 4...8))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animate
                        )
                    }
                }
            }

            VStack(spacing: 30) {
                Spacer()

                ZStack {
                    // Outer glow
                    Circle()
                        .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .blur(radius: 2)

                    // Inner circle
                    Circle()
                        .fill(Color.black)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#00FF00"), lineWidth: 2)
                        )

                    // Logo text
                    Text("CM")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                }
                .opacity(pulseOpacity ? 0.8 : 1.0)

                if showWelcome {
                    Text("Welcome to CaringMind")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                        .opacity(showWelcome ? 1 : 0)
                }

                if state.navigation.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00FF00")))
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 16) {
                        Button(action: signInWithGoogle) {
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .font(.system(size: 20))
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color(hex: "#00FF00").opacity(0.3), radius: 5)
                        }
                        .disabled(state.auth.isAuthenticated)
                    }
                    .opacity(showButtons ? 1 : 0)
                }
            }
            .padding(.horizontal, 30)
        }
        .alert("Authentication Error", isPresented: .constant(state.auth.error != nil)) {
            Button("OK", role: .cancel) {
                store.dispatch(AuthAction.clearError)
            }
        } message: {
            if let error = state.auth.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            store.subscribe(self)
            withAnimation(.easeOut(duration: 0.8)) { animate = true }
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseOpacity = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showWelcome = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showButtons = true
                }
            }
        }
        .onDisappear {
            store.unsubscribe(self)
        }
    }

    private func signInWithGoogle() {
        store.dispatch(NavigationAction.setLoading(true))

        #if os(iOS)
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            store.dispatch(AuthAction.signInFailure(.unknown))
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            store.dispatch(NavigationAction.setLoading(false))

            if let error = error {
                store.dispatch(AuthAction.signInFailure(.signInFailed(error)))
                return
            }

            guard let user = signInResult?.user else {
                store.dispatch(AuthAction.signInFailure(.noUserID))
                return
            }

            store.dispatch(AuthAction.signIn(user))
        }
        #endif
    }
}

// MARK: - StoreSubscriber
extension SplashView: StoreSubscriber {
    func newState(state: AppState) {
        self.state = state
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

struct SplashBackgroundGradientView: View {
    var colors: [Color] = [Color.blue, Color.purple]

    var body: some View {
        LinearGradient(gradient: Gradient(colors: colors),
                       startPoint: .top,
                       endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
    }
}
