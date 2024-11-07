// NameInputView.swift

import SwiftUI

struct NameInputView: View {
   @Binding var userName: String
   @Binding var step: Int
   
   @StateObject private var appManager = AppManager()
   
   @State private var receivedName: String = ""
   @State private var prosody: String = ""
   @State private var feeling: String = ""
   @State private var confidenceScore: Int = 0
   @State private var confidenceReasoning: String = ""
   @State private var psychoanalysis: String = ""
   @State private var locationBackground: String = ""
   
   @State private var isCorrectName: Bool = true
   @State private var confirmedName: String = ""
   @State private var isRecording: Bool = false
   @State private var currentPrompt: String = "Say: \"Hello, I'm [your name]!\""
   @State private var showConfirmation: Bool = false
   @State private var pulseOpacity = false
   
   private let greetings = [
       "Say: \"Hello, I'm [your name]!\"",
       "Di: \"Hola, soy [tu nombre]!\"",
       "Dire: \"Bonjour, je suis [votre nom]!\"",
       "Sag: \"Hallo, ich bin [dein Name]!\"",
       "说: \"你好，我是[你的名字]!\"",
       "Diga: \"Olá, eu sou [seu nome]!\"",
       "Say: \"こんにちは、私は[あなたの名前]です!\"",
       "Gul: \"Merhaba, ben [senin ismin]!\""
   ]
   
   private let demoWaveform: [CGFloat] = [0.2, 0.5, 0.3, 0.7, 0.2, 0.6, 0.4, 0.8, 0.3, 0.6, 0.4]
   @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
   
   var body: some View {
       ScrollView {
           VStack {
               Spacer()
               
               if !showConfirmation {
                   VStack(spacing: 20) {
                       Text(currentPrompt)
                           .font(.system(size: 24, weight: .bold, design: .monospaced))
                           .foregroundColor(Color(hex: "#00FF00"))
                           .multilineTextAlignment(.center)
                           .padding(.horizontal, 30)
                           .onReceive(timer) { _ in
                               currentPrompt = greetings.randomElement() ?? currentPrompt
                           }
                       
                       // Waveform visualization
                       HStack(spacing: 6) {
                           ForEach(demoWaveform.indices, id: \.self) { index in
                               Capsule()
                                   .fill(isRecording ? Color(hex: "#00FF00") : Color(hex: "#00FF00").opacity(0.4))
                                   .frame(width: 4, height: demoWaveform[index] * 60)
                           }
                       }
                       .padding(.vertical, 30)
                       .background(
                           RoundedRectangle(cornerRadius: 16)
                               .fill(Color.black)
                               .overlay(
                                   RoundedRectangle(cornerRadius: 16)
                                       .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                               )
                       )
                       .shadow(color: Color(hex: "#00FF00").opacity(0.2), radius: 10)
                       
                       Button(action: {
                           isRecording.toggle()
                           if isRecording {
                               appManager.startRecording()
                           } else {
                               appManager.stopRecordingAndSendAudio { result in
                                   switch result {
                                   case .success(let response):
                                       self.receivedName = response.name
                                       self.prosody = response.prosody
                                       self.feeling = response.feeling
                                       self.confidenceScore = response.confidence_score
                                       self.confidenceReasoning = response.confidence_reasoning
                                       self.psychoanalysis = response.psychoanalysis
                                       self.locationBackground = response.location_background
                                       self.showConfirmation = true
                                   case .failure(let error):
                                       print("Error: \(error.localizedDescription)")
                                   }
                               }
                           }
                       }) {
                           HStack {
                               Image(systemName: "waveform")
                                   .font(.system(size: 20))
                               Text(isRecording ? "LISTENING..." : "INITIALIZE VOICE")
                                   .font(.system(size: 16, weight: .bold, design: .monospaced))
                           }
                           .foregroundColor(isRecording ? .black : Color(hex: "#00FF00"))
                           .frame(width: 280, height: 56)
                           .background(
                               ZStack {
                                   RoundedRectangle(cornerRadius: 8)
                                       .fill(isRecording ? Color(hex: "#00FF00") : Color.black)
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                                       .blur(radius: 3)
                                       .opacity(pulseOpacity ? 0.8 : 0.2)
                               }
                           )
                       }
                   }
                   .frame(maxWidth: .infinity)
               } else {
                   VStack(spacing: 20) {
                       Text("did i hear you right?")
                           .font(.system(size: 24, weight: .bold, design: .monospaced))
                           .foregroundColor(Color(hex: "#00FF00"))
                       
                       Text(receivedName)
                           .font(.system(size: 32, weight: .bold, design: .monospaced))
                           .foregroundColor(Color(hex: "#00FF00"))
                       
                       VoiceAnalysisCard(
                           prosody: prosody,
                           feeling: feeling,
                           confidenceScore: confidenceScore,
                           confidenceReasoning: confidenceReasoning,
                           psychoanalysis: psychoanalysis,
                           locationBackground: locationBackground
                       )
                       .padding(.horizontal)
                       
                       VStack {
                           Toggle(isOn: $isCorrectName) {
                               Text(isCorrectName ? "IDENTITY VERIFIED" : "MANUAL OVERRIDE")
                                   .font(.system(size: 14, weight: .medium, design: .monospaced))
                                   .foregroundColor(Color(hex: "#00FF00"))
                           }
                           .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#00FF00")))
                       }
                       .padding(.horizontal, 40)
                       .padding(.vertical, 10)
                       
                       if !isCorrectName {
                           TextField("ENTER CORRECT IDENTITY", text: $confirmedName)
                               .font(.system(size: 16, design: .monospaced))
                               .foregroundColor(Color(hex: "#00FF00"))
                               .textFieldStyle(PlainTextFieldStyle())
                               .padding()
                               .background(Color.black)
                               .overlay(
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                               )
                               .padding(.horizontal, 40)
                               .onAppear {
                                   confirmedName = receivedName
                               }
                       }
                       
                       Button(action: {
                           userName = isCorrectName ? receivedName : confirmedName
                           step += 1
                       }) {
                           Text("PROCESS >>")
                               .font(.system(size: 18, weight: .bold, design: .monospaced))
                               .foregroundColor(.black)
                               .frame(width: 280, height: 56)
                               .background(
                                   RoundedRectangle(cornerRadius: 8)
                                       .fill(Color(hex: "#00FF00"))
                               )
                       }
                   }
                   .frame(maxWidth: .infinity)
               }
               
               Spacer()
           }
           .padding()
       }
       .background(Color.black)
       .onAppear {
           withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
               pulseOpacity = true
           }
       }
       .alert(isPresented: $appManager.showingError) {
           Alert(
               title: Text("Error"),
               message: Text(appManager.errorMessage ?? "An unknown error occurred."),
               dismissButton: .default(Text("OK"))
           )
       }
   }
}
