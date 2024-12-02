//  Onboarding.swift
//  CaringMind
//  Created by Elijah Arbee on 10/30/24.
//
import SwiftUI
import Combine
import GoogleSignIn
import GoogleSignInSwift
import ReSwift

struct OnboardingIntroView: View {
   @EnvironmentObject var router: AppRouterViewModel
   @Binding var step: Int
   @Binding var userName: String
   // @Binding var age: String
   @State private var pulseOpacity = false

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
                       .offset(x: pulseOpacity ? 50 : -50)
                       .animation(
                           Animation.linear(duration: Double.random(in: 4...8))
                               .repeatForever(autoreverses: true)
                               .delay(Double(index) * 0.2),
                           value: pulseOpacity
                       )
                   }
               }
           }

           VStack {
               Spacer()

               switch step {
               case 0:
                   WelcomeView(step: $step)
               case 1:
                   MomentsThoughtsEmotionsView(step: $step)
               case 2:
                   ManageDataView(step: $step)
               case 3:
                   NameInputView(userName: $userName, step: $step)
               case 4:
                   TruthLieGameView(step: $step)
               case 5:
                   FinalStepView(userName: userName)
               default:
                   Text("INITIALIZATION COMPLETE")
                       .font(.system(size: 24, weight: .bold, design: .monospaced))
                       .foregroundColor(Color(hex: "#00FF00"))
                       .onAppear {
                           router.navigate(to: .home)
                       }
               }

               Spacer()
           }
       }
       .onAppear {
           withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
               pulseOpacity = true
           }
       }
   }
}

struct CyberText: ViewModifier {
   func body(content: Content) -> some View {
       content
           .font(.system(.body, design: .monospaced))
           .foregroundColor(Color(hex: "#00FF00"))
           .multilineTextAlignment(.center)
   }
}

struct WelcomeView: View {
   @Binding var step: Int
   @State private var textOpacity = 0.0

   var body: some View {
       Text("I’m Mahdi, your personal consciousness companion. Together, we’ll navigate your journey towards a balanced and fulfilling life.") // prev. INITIALIZING CONSCIOUSNESS COMPANION but want to make more user friendly, this app is an advocate for the user, and acts in principle with the muslimic mahdi concept
           .modifier(CyberText())
           .font(.system(size: 24, weight: .bold, design: .monospaced))
           .opacity(textOpacity)
           .padding(.horizontal, 30)
           .onAppear {
               withAnimation(.easeIn(duration: 0.5)) {
                   textOpacity = 1.0
               }
               DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                   withAnimation {
                       step += 1
                   }
               }
           }
   }
}

struct MomentsThoughtsEmotionsView: View {
    @Binding var step: Int
    @State private var textOpacity = 0.0
    @State private var nodeOpacity = Array(repeating: 0.0, count: 4)
    @State private var lineOpacity = Array(repeating: 0.0, count: 3)
    @State private var pulseScale: CGFloat = 1.0
    @State private var dataFlowPhase = Array(repeating: 0.0, count: 3)

    // Circuit pattern background
    struct CircuitPatternView: View {
        var body: some View {
            GeometryReader { geometry in
                Path { path in
                    // Create circuit-like pattern
                    let gridSize: CGFloat = 40
                    for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                        for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gridSize, y: y))
                            if Bool.random() {
                                path.move(to: CGPoint(x: x, y: y))
                                path.addLine(to: CGPoint(x: x, y: y + gridSize))
                            }
                        }
                    }
                }
                .stroke(Color(hex: "#00FF00").opacity(0.1), lineWidth: 0.5)
            }
        }
    }

    // Animated connection line
    struct DataFlowLine: View {
        let start: CGPoint
        let end: CGPoint
        let phase: CGFloat

        var body: some View {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                Color(hex: "#00FF00"),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [4, 4],
                    dashPhase: phase
                )
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circuit pattern
                CircuitPatternView()

                // Center position for main node
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height * 0.4  // Lowered position

                // Connection lines with data flow
                ForEach(0..<3) { index in
                    let endX = centerX + CGFloat(index - 1) * 120
                    let endY = centerY + 150

                    DataFlowLine(
                        start: CGPoint(x: centerX, y: centerY),
                        end: CGPoint(x: endX, y: endY),
                        phase: dataFlowPhase[index]
                    )
                    .opacity(lineOpacity[index])
                }

                // Central LIFE=DATA node **DO NOT REMOVE**
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#00FF00"), lineWidth: 2)
                        )
                        .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)

                    Text("LIFE\n=\nDATA")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                        .multilineTextAlignment(.center)
                }
                .position(x: centerX, y: centerY)
                .scaleEffect(pulseScale)
                .opacity(nodeOpacity[0])

                // Child nodes
                ForEach(0..<3) { index in
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#00FF00"), lineWidth: 2)
                            )
                            .shadow(color: Color(hex: "#00FF00").opacity(0.3), radius: 8)

                        Text(["MOMENTS", "THOUGHTS", "EMOTIONS"][index])
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))
                            .multilineTextAlignment(.center)
                    }
                    .position(
                        x: centerX + CGFloat(index - 1) * 120,
                        y: centerY + 150
                    )
                    .opacity(nodeOpacity[index + 1])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                // Start animations
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        // Animate nodes appearing
        for i in 0..<4 {
            withAnimation(.easeIn(duration: 0.5).delay(Double(i) * 0.3)) {
                nodeOpacity[i] = 1.0
            }
        }

        // Animate lines appearing
        for i in 0..<3 {
            withAnimation(.easeIn(duration: 0.5).delay(1.2 + Double(i) * 0.2)) {
                lineOpacity[i] = 1.0
            }
        }

        // Start pulsing animation for central node
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Animate data flow along lines
        for i in 0..<3 {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                dataFlowPhase[i] = 20.0
            }
        }

        // Proceed to next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                step += 1
            }
        }
    }
}

struct ManageDataView: View {
   @Binding var step: Int
   @State private var textOpacity = 0.0

   var body: some View {
       Text("what you make of data determines your life ") // this stays
           .modifier(CyberText())
           .font(.system(size: 24, weight: .bold, design: .monospaced))
           .opacity(textOpacity)
           .padding(.horizontal, 30)
           .onAppear {
               withAnimation(.easeIn(duration: 0.5)) {
                   textOpacity = 1.0
               }
               DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                   withAnimation {
                       step += 1
                   }
               }
           }
   }
}

struct FinalStepView: View {
   var userName: String
   // var age: String
   @EnvironmentObject var router: AppRouterViewModel
   @State private var pulseOpacity = false

   var body: some View {
       VStack(spacing: 20) {
           Spacer()

           Text("NEURAL LINK ESTABLISHED")
               .modifier(CyberText())
               .font(.system(size: 24, weight: .bold, design: .monospaced))

           Text("USER: \(userName.uppercased())")
               .modifier(CyberText())
               .font(.system(size: 18, design: .monospaced))
               .padding(.horizontal, 30)

           Spacer()

           Button(action: { signInWithGoogle() }) {
               HStack(spacing: 12) {
                   Image(systemName: "network")
                       .font(.system(size: 20))
                       .foregroundColor(Color(hex: "#00FF00"))

                   Text("SYNC WITH NETWORK")
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

           Button(action: { router.navigate(to: .home) }) {
               Text("INITIALIZE")
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

           Spacer()
       }
       .onAppear {
           withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
               pulseOpacity = true
           }
       }
   }

   private func signInWithGoogle() {
       #if os(iOS)
       guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
             let rootViewController = windowScene.windows.first?.rootViewController else {
           print("Could not get root view controller")
           return
       }

       GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
           if let error = error {
               print("Google Sign-In failed: \(error.localizedDescription)")
               return
           }

           guard let signInResult = signInResult else { return }
           let user = signInResult.user
           print("Successfully signed in as \(user.profile?.name ?? "Unknown")")

           DispatchQueue.main.async {
               self?.router.navigate(to: .home)
           }
       }
       #elseif os(macOS)
       // Implement macOS specific sign-in flow
       print("Google Sign-In not yet implemented for macOS")
       #endif
   }
}

class OnboardingViewModel: ObservableObject {
   @Published var currentStep: Int = 0 {
       didSet {
           saveCurrentStep()
       }
   }

   @Published var userName: String = "" {
       didSet {
           userInputs["userName"] = userName
           saveUserInputs()
       }
   }

   @Published var userInputs: [String: String] = [:] {
       didSet {
           saveUserInputs()
       }
   }

   let totalSteps: Int = 7

   var progressValue: Double {
       Double(currentStep) / Double(totalSteps)
   }

   init() {
       loadState()
   }

   // MARK: - Audio Input Note
   // the user input should be an audio file
   // the user will say '{greeting}, im {username}
   // we will then send the audio to backend and the backend will respond with
   /**
    {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "description": "The user's full name.",
          "example": "Alan Rodrigues"
        },
        "prosody": {
          "type": "string",
          "description": "An analysis of the user's speech characteristics.",
          "example": "The user's pronunciation of 'Alan' is somewhat hesitant."
        },
        "feeling": {
          "type": "string",
          "description": "An interpretation of the user's emotional tone.",
          "example": "There's a slight air of reluctance in the delivery."
        }
      },
      "required": ["name", "prosody", "feeling"]
    }
    */
   // we will only display the user name however and save the other results alongside the name
   // if spelling wrong user should correct, if name totally wrong prompt to repeat once more
   // use openaudio for this

   // MARK: - Data Persistence
   private func saveCurrentStep() {
       guard UserDefaults.standard.bool(forKey: "isUserSignedInWithGoogle") else { return }
       UserDefaults.standard.set(currentStep, forKey: "currentStep")
   }

   private func saveUserInputs() {
       guard UserDefaults.standard.bool(forKey: "isUserSignedInWithGoogle") else { return }
       UserDefaults.standard.set(userInputs, forKey: "userInputs")
   }

   private func loadState() {
       guard UserDefaults.standard.bool(forKey: "isUserSignedInWithGoogle") else { return }

       currentStep = UserDefaults.standard.integer(forKey: "currentStep")
       userInputs = UserDefaults.standard.dictionary(forKey: "userInputs") as? [String: String] ?? [:]
       userName = userInputs["userName"] ?? ""
   }

   // MARK: - Navigation
   func nextStep() {
       guard currentStep < totalSteps else { return }
       currentStep += 1
   }

   func previousStep() {
       guard currentStep > 0 else { return }
       currentStep -= 1
   }
}
