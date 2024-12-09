import SwiftUI
import Combine

struct NameInputView: View {
    @Binding var userName: String
    @Binding var step: Int
    
    @StateObject private var viewModel = NameInputViewModel()
    
    // MARK: - State Variables
    @State private var isCorrectName: Bool = true
    @State private var confirmedName: String = ""
    @State private var isRecording: Bool = false
    @State private var showInstructions: Bool = false
    @State private var pulseOpacity: Bool = false
    @State private var typingText: String = ""
    @State private var currentTypingIndex: Int = 0
    @State private var waveformAnimation: Bool = false
    
    private let demoWaveform: [CGFloat] = [0.2, 0.5, 0.3, 0.7, 0.2, 0.6, 0.4, 0.8, 0.3, 0.6, 0.4]
    @State private var timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()
    
    @State private var circuitPhase: CGFloat = 0
    
    // MARK: - Body
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
                    
                    if !viewModel.showConfirmation {
                        recordingSection
                    } else {
                        confirmationSection
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if viewModel.isUploading {
                    uploadingOverlay
                }
                if showInstructions {
                    instructionsOverlay
                }
            }
        )
        .background(Color.black)
        .onAppear {
            startNewTypingAnimation()
            startAnimations()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - View Components
    private var circuitBackground: some View {
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
    
    private var recordingSection: some View {
        VStack(spacing: 25) {
            Text("Voice Identification")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
            
            Text(typingText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .onReceive(timer) { _ in
                    startNewTypingAnimation()
                }
            
            Button(action: { showInstructions.toggle() }) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("How to Record")
                }
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
            }
            
            waveformView
            
            recordButton
        }
    }
    
    private var waveformView: some View {
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
    }
    
    private var recordButton: some View {
        Button(action: handleRecordButton) {
            HStack {
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 24))
                    .symbolEffect(.bounce, value: isRecording)
                Text(isRecording ? "Listening..." : "Speak")
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
    
    private var confirmationSection: some View {
        VStack(spacing: 30) {
            Text("I Heard...")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .opacity(0.8)
            
            Text(viewModel.receivedName)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#00FF00"))
                .shadow(color: Color(hex: "#00FF00").opacity(0.5), radius: 10)
            
            VoiceAnalysisCard(response: ServerResponse(
                name: viewModel.receivedName,
                prosody: viewModel.prosody,
                feeling: viewModel.feeling,
                confidence_score: viewModel.confidenceScore,
                confidence_reasoning: viewModel.confidenceReasoning,
                psychoanalysis: viewModel.psychoanalysis,
                location_background: viewModel.locationBackground
            ))
            .padding(.horizontal)
            
            VStack {
                Toggle(isOn: $isCorrectName) {
                    Text(isCorrectName ? "That's Me" : "Not Quite Right")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                }
                .toggleStyle(CyberpunkToggleStyle())
            }
            .padding(.horizontal, 40)
            
            if !isCorrectName {
                TextField("Tell me your name", text: $confirmedName)
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
                        confirmedName = viewModel.receivedName
                    }
            }
            
            HStack(spacing: 20) {
                Button(action: confirmName) {
                    Text("Continue >>")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 200, height: 56)
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
                
                Button(action: retryRecording) {
                    Text("Retry")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00"))
                        .frame(width: 120, height: 56)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                            }
                        )
                }
            }
        }
    }
    
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00FF00")))
                    .scaleEffect(1.5)
                
                Text("Analyzing voice pattern...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
            }
        }
    }
    
    private var instructionsOverlay: some View {
        VStack(spacing: 20) {
            Text("How to Record")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            
            VStack(alignment: .leading, spacing: 15) {
                Text("1. Tap 'Speak' when ready.")
                Text("2. Clearly state your name.")
                Text("3. Speak naturally.")
                Text("4. Tap again when finished.")
                Text("5. Verify the analysis.")
            }
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            
            Button("Got It") {
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
    
    // MARK: - Helper Functions
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
        let newPrompt = Greetings.allGreetings.randomElement() ?? "Say: \"Hello, I'm John Doe\""
        
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
    
    private func handleRecordButton() {
        if isRecording {
            stopRecording()
            viewModel.processAudioFile()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        viewModel.startRecording()
        isRecording = true
        startAnimations()
    }
    
    private func stopRecording() {
        isRecording = false
        viewModel.stopRecording()
        pulseOpacity = false
    }
    
    private func confirmName() {
        let nameToSave = isCorrectName ? viewModel.receivedName : confirmedName
        viewModel.confirmName(isCorrectName: isCorrectName, confirmedName: confirmedName)
        userName = nameToSave
        step += 1
    }
    
    private func retryRecording() {
        viewModel.resetState()
        isRecording = false
        pulseOpacity = false
    }
}

// MARK: - Custom Styles
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

#Preview {
    NameInputView(userName: .constant(""), step: .constant(0))
        .preferredColorScheme(.dark)
}
