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
// maybe add globe to background [circle] maybe other noise
struct SplashView: View {
   @EnvironmentObject var router: AppRouterViewModel
   @EnvironmentObject var authManager: AuthenticationManager
   @State private var animate = false
   @State private var pulseOpacity = false
   @State private var showWelcome = false
   @State private var showButtons = false
   
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
                       .frame(width: 110, height: 110)
                       .blur(radius: 5)
                       .opacity(pulseOpacity ? 0.8 : 0.2)
                       .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                   
                   // Inner container
                   Circle()
                       .fill(Color.black)
                       .frame(width: 100, height: 100)
                       .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                   
                   // App Icon with border
                   ZStack {
                       #if os(iOS)
                       if let image = UIImage(named: "AppIcon") {
                           Image(uiImage: image)
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 90, height: 90)
                               .clipShape(Circle())
                               .padding(5)
                               .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                       } else {
                           Image(systemName: "app")
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 90, height: 90)
                               .clipShape(Circle())
                               .padding(5)
                               .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                       }
                       #else
                       if let image = NSImage(named: "AppIcon") {
                           Image(nsImage: image)
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 90, height: 90)
                               .clipShape(Circle())
                               .padding(5)
                               .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                       } else {
                           Image(systemName: "app")
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 90, height: 90)
                               .clipShape(Circle())
                               .padding(5)
                               .scaleEffect(pulseOpacity ? 1.1 : 1.0)
                       }
                       #endif
                       Circle()
                           .stroke(Color(hex: "#00FF00"), lineWidth: 2)
                   }
               }
               .padding(.bottom, 20)
               
               VStack(spacing: 12) {
                   Text("mahdi")
                       .font(.system(size: 32, weight: .bold, design: .monospaced))
                       .foregroundColor(Color(hex: "#00FF00"))
                       .opacity(showWelcome ? 1 : 0)
                   
                   Text("your consciousness companion")
                       .font(.system(size: 14, weight: .medium, design: .monospaced))
                       .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
                       .opacity(showWelcome ? 1 : 0)
                       .tracking(2)
               }
               
               Spacer()
               
               VStack(spacing: 16) {
                   Button(action: signInWithGoogle) {
                       HStack(spacing: 12) {
                           Image(systemName: "network")
                               .font(.system(size: 20))
                               .foregroundColor(Color(hex: "#00FF00"))
                           
                           Text("SIGN IN")
                               .font(.system(size: 16, weight: .bold, design: .monospaced))
                               .foregroundColor(Color(hex: "#00FF00"))
                       }
                       .frame(width: 280, height: 56)
                       .background(
                           ZStack {
                               RoundedRectangle(cornerRadius: 8)
                                   .fill(Color.black)
                               RoundedRectangle(cornerRadius: 8)
                                   .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                               RoundedRectangle(cornerRadius: 8)
                                   .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                                   .blur(radius: 3)
                                   .opacity(pulseOpacity ? 0.8 : 0.2)
                           }
                       )
                   }
                   
                   Button(action: { router.navigate(to: .onboarding) }) {
                       Text("Get Started")
                           .font(.system(size: 18, weight: .bold, design: .monospaced))
                           .foregroundColor(.black)
                           .frame(width: 280, height: 56)
                           .background(
                               ZStack {
                                   RoundedRectangle(cornerRadius: 8)
                                       .fill(Color(hex: "#00FF00"))
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color(hex: "#00FF00").opacity(0.8), lineWidth: 1)
                                       .blur(radius: 3)
                                       .opacity(pulseOpacity ? 0.8 : 0.2)
                               }
                           )
                   }
               }
               .offset(y: showButtons ? 0 : 40)
               .opacity(showButtons ? 1 : 0)
               
               Spacer().frame(height: 50)
           }
           .padding(.horizontal, 30)
       }
       .onAppear {
           withAnimation(.easeOut(duration: 0.8)) { animate = true }
           withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
               pulseOpacity = true
           }
           withAnimation(.easeOut(duration: 0.8).delay(0.3)) { showWelcome = true }
           withAnimation(.easeOut(duration: 0.8).delay(0.6)) { showButtons = true }
       }
   }
   
   func signInWithGoogle() {
       #if os(iOS)
       guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
       
       GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
           if let error = error {
               print("Error signing in: \(error.localizedDescription)")
               return
           }
           
           guard let signInResult = signInResult else { return }
           authManager.handleSignIn(user: signInResult.user)
       }
       #endif
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
