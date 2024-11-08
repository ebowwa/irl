// TODO: can we do a `was i wrong q? and only this allowing another analyzation; with this second attempt can we send bothh audios and a message to one identify which is which and explain to focus on spotting the lie only in the second
// NOTE: this is a good example of having the ui await the server response - i will need to carry this over to the truth game as well

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
    @State private var isUploading = false
    @State private var currentPrompt: String = "Say: \"Hello, I'm [your name]!\""
    @State private var showConfirmation: Bool = false
    @State private var showInstructions = false
    @State private var pulseOpacity = false
    @State private var typingText = ""
    @State private var currentTypingIndex = 0
    
    private let greetings = [
        "Say: \"Hello, I'm [your name]\"",
        "Di: \"Hola, soy [tu nombre]\"",
        "Dire: \"Bonjour, je suis [votre nom]\"",
        "Sag: \"Hallo, ich bin [dein Name]\"",
        "说: \"你好，我是[你的名字]\"",
        "Diga: \"Olá, eu sou [seu nome]\"",
        "Say: \"こんにちは、私は[あなたの名前]です\"",
        "Gul: \"Merhaba, ben [senin ismin]\""
    ]
    
    private let demoWaveform: [CGFloat] = [0.2, 0.5, 0.3, 0.7, 0.2, 0.6, 0.4, 0.8, 0.3, 0.6, 0.4]
    @State private var timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()
    @State private var waveformAnimation = false
    
    @State private var circuitPhase: CGFloat = 0
    
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00FF00")))
                    .scaleEffect(1.5)
                
                Text("analyzing voice pattern...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
            }
        }
    }
    
    var circuitBackground: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 30
                
                for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                    for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gridSize, y: y))
                        }
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + gridSize))
                        }
                    }
                }
            }
            .stroke(Color(hex: "#00FF00").opacity(0.1), style: StrokeStyle(
                lineWidth: 1,
                lineCap: .round,
                lineJoin: .round,
                dashPhase: circuitPhase
            ))
        }
    }
    
    var body: some View {
        ZStack {
            circuitBackground
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        circuitPhase = 1000
                    }
                }
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    
                    if !showConfirmation {
                        VStack(spacing: 25) {
                            Text("voice identification")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                            
                            Text("tell me your name")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                            
                            Button(action: { showInstructions.toggle() }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("how to record")
                                }
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
                            }
                            
                            Text(typingText)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .onReceive(timer) { _ in
                                    startNewTypingAnimation()
                                }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#00FF00").opacity(0.1))
                                    .blur(radius: 10)
                                    .scaleEffect(waveformAnimation ? 1.1 : 1.0)
                                
                                HStack(spacing: 6) {
                                    ForEach(demoWaveform.indices, id: \.self) { index in
                                        Capsule()
                                            .fill(isRecording ? Color(hex: "#00FF00") : Color(hex: "#00FF00").opacity(0.4))
                                            .frame(width: 4, height: demoWaveform[index] * 60)
                                            .animation(
                                                Animation
                                                    .easeInOut(duration: 0.5)
                                                    .repeatForever()
                                                    .delay(Double(index) * 0.1),
                                                value: isRecording
                                            )
                                    }
                                }
                                .padding(.vertical, 30)
                            }
                            .frame(height: 120)
                            .padding(.horizontal)
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isRecording.toggle()
                                }
                                if isRecording {
                                    appManager.startRecording()
                                } else {
                                    isUploading = true
                                    appManager.stopRecordingAndSendAudio { result in
                                        isUploading = false
                                        switch result {
                                        case .success(let response):
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                self.receivedName = response.name
                                                self.prosody = response.prosody
                                                self.feeling = response.feeling
                                                self.confidenceScore = response.confidence_score
                                                self.confidenceReasoning = response.confidence_reasoning
                                                self.psychoanalysis = response.psychoanalysis
                                                self.locationBackground = response.location_background
                                                self.showConfirmation = true
                                            }
                                        case .failure(let error):
                                            print("Error: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                                        .font(.system(size: 24))
                                        .symbolEffect(.bounce, value: isRecording)
                                    Text(isRecording ? "listening..." : "speak")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(isRecording ? .black : Color(hex: "#00FF00"))
                                .frame(width: 280, height: 56)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isRecording ? Color(hex: "#00FF00") : Color.black)
                                            .shadow(color: Color(hex: "#00FF00").opacity(isRecording ? 0.6 : 0.3), radius: 10)
                                        
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
                    } else {
                        VStack(spacing: 30) {
                            Text("i heard...")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                                .opacity(0.8)
                            
                            Text(receivedName)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                                .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)
                            
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
                                    Text(isCorrectName ? "that's me" : "not quite right")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color(hex: "#00FF00"))
                                }
                                .toggleStyle(CyberpunkToggleStyle())
                            }
                            .padding(.horizontal, 40)
                            
                            if !isCorrectName {
                                TextField("tell me your name", text: $confirmedName)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(Color(hex: "#00FF00"))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black)
                                            .shadow(color: Color(hex: "#00FF00").opacity(0.3), radius: 5)
                                    )
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
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    userName = isCorrectName ? receivedName : confirmedName
                                    step += 1
                                }
                            }) {
                                Text("connect >>")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 280, height: 56)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: "#00FF00"))
                                                .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "#00FF00").opacity(0.5), lineWidth: 1)
                                                .blur(radius: 3)
                                        }
                                    )
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if isUploading {
                    uploadingOverlay
                        .transition(.opacity)
                }
                if showInstructions {
                    VStack(spacing: 20) {
                        Text("how to record")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("1. tap speak when ready")
                            Text("2. clearly state your name")
                            Text("3. speak naturally")
                            Text("4. tap again when finished")
                            Text("5. verify the analysis")
                        }
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        
                        Button("got it") {
                            showInstructions = false
                        }
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    .padding()
                    .foregroundColor(Color(hex: "#00FF00"))
                    .background(Color.black.opacity(0.95))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    )
                    .padding()
                }
            }
        )
        .background(Color.black)
        .onAppear {
            startNewTypingAnimation()
            startAnimations()
        }
        .alert(isPresented: $appManager.showingError) {
            Alert(
                title: Text("connection lost"),
                message: Text(appManager.errorMessage ?? "something went wrong"),
                dismissButton: .default(Text("try again"))
            )
        }
    }
    
    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseOpacity = true
        }
        
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waveformAnimation = true
        }
    }
    
    private func startNewTypingAnimation() {
        typingText = ""
        currentTypingIndex = 0
        let newPrompt = greetings.randomElement() ?? currentPrompt

func typeNextCharacter() {
            guard currentTypingIndex < newPrompt.count else { return }
            
            typingText += String(newPrompt[newPrompt.index(newPrompt.startIndex, offsetBy: currentTypingIndex)])
            currentTypingIndex += 1
            
            if currentTypingIndex < newPrompt.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    typeNextCharacter()
                }
            }
        }
        
        typeNextCharacter()
    }
}

// Custom Cyberpunk Toggle Style
struct CyberpunkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color(hex: "#00FF00").opacity(0.3) : Color.black)
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    )
                
                Circle()
                    .fill(configuration.isOn ? Color(hex: "#00FF00") : Color(hex: "#00FF00").opacity(0.5))
                    .frame(width: 24, height: 24)
                    .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 5)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}


struct NameInputView_Previews: PreviewProvider {
    static var previews: some View {
        NameInputView(userName: .constant(""), step: .constant(0))
            .preferredColorScheme(.dark)
    }
}
