//
//  TruthLieGameView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/5/24.
//
// once the audio is sent, unless the audio fails, remove the begin button, 
import SwiftUI

// MARK: 1. Reusable Card View
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    Color.black
                    // Circuit pattern design
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            // Create circuit pattern with random elements
                            path.move(to: CGPoint(x: 0, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
                            
                            path.move(to: CGPoint(x: width, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
                            
                            // Additional circuit elements
                            for i in stride(from: 0, to: width, by: 40) {
                                if Bool.random() {
                                    path.move(to: CGPoint(x: i, y: 0))
                                    path.addLine(to: CGPoint(x: i + 20, y: 20))
                                }
                            }
                        }
                        .stroke(Color(hex: "#00FF00").opacity(0.1), lineWidth: 0.5)
                    }
                }
            )
            .cornerRadius(15)
            .shadow(color: Color(hex: "#00FF00").opacity(0.2), radius: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(hex: "#00FF00").opacity(0.3), lineWidth: 1)
            )
            .frame(maxWidth: 350, maxHeight: 500)
    }
}

// MARK: 2. Swipeable Card View
struct SwipeableCardView: View {
    let statement: StatementAnalysis
    let onSwipe: (_ direction: AnalysisService.SwipeDirection, _ statement: StatementAnalysis) -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var glowIntensity: Double = 0

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    if statement.isTruth {
                        Text("truth")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color(hex: "#00FF00"))
                    } else {
                        Text("deception")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))
                        Spacer()
                        Image(systemName: "wand.and.rays")
                            .foregroundColor(Color(hex: "#00FF00"))
                    }
                }

                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.3))

                Text(statement.statement)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
                
                // Swipe instruction hint
                Text("< swipe to analyze >")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00").opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            }
            .padding()
        }
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 10)))
        .gesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    self.offset = gesture.translation
                }
                .onEnded { gesture in
                    let swipeThreshold: CGFloat = 100
                    if gesture.translation.width > swipeThreshold {
                        withAnimation {
                            self.offset = CGSize(width: 1000, height: 0)
                        }
                        onSwipe(.right, statement)
                    } else if gesture.translation.width < -swipeThreshold {
                        withAnimation {
                            self.offset = CGSize(width: -1000, height: 0)
                        }
                        onSwipe(.left, statement)
                    } else {
                        withAnimation {
                            self.offset = .zero
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: offset)
    }
}

// MARK: 3. Main Analysis View
struct TruthLieGameView: View {
    @Binding var step: Int
    @StateObject private var service = AnalysisService()
    @State private var showInstructions = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                recordingContainer
                
                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.3))
                
                ZStack {
                    if service.showSummary {
                        summaryCard
                            .transition(.opacity)
                    } else {
                        if service.statements.filter({ !service.swipedStatements.contains($0.id) }).isEmpty && service.response != nil {
                            Text("analysis complete")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                        } else {
                            ForEach(service.statements) { statement in
                                if !service.swipedStatements.contains(statement.id) {
                                    SwipeableCardView(statement: statement) { direction, swipedStatement in
                                        service.handleSwipe(direction: direction, for: swipedStatement)
                                    }
                                    .stacked(at: index(of: statement), in: service.statements.count)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .overlay(
            Group {
                if showInstructions {
                    instructionsOverlay
                }
            }
        )
        .alert(item: $service.recordingError) { error in
            Alert(
                title: Text("error"),
                message: Text(error.message),
                dismissButton: .default(Text("retry"))
            )
        }
    }

    // MARK: 4. Recording Container
    private var recordingContainer: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("truth protocol")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
                
                Text("tell me two truths and a lie")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00").opacity(0.8))
                
                Button(action: { showInstructions.toggle() }) {
                    Label("how to play", systemImage: "info.circle")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#00FF00").opacity(0.6))
                }
            }
            
            Button(action: {
                if service.isRecording {
                    service.stopRecording()
                    service.uploadRecording()
                } else {
                    service.startRecording()
                }
            }) {
                HStack {
                    Image(systemName: service.isRecording ? "stop.circle" : "waveform.circle")
                    Text(service.isRecording ? "analyzing..." : "begin")
                }
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(service.isRecording ? .black : Color(hex: "#00FF00"))
                .frame(width: 280, height: 56)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(service.isRecording ? Color(hex: "#00FF00") : Color.black)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                    }
                )
            }

            if let response = service.response {
                Text("statements detected. swipe to analyze.")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#00FF00"))
            }
        }
        .padding()
    }

    // MARK: 5. Instructions Overlay
    private var instructionsOverlay: some View {
        VStack(spacing: 20) {
            Text("how to play")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            
            VStack(alignment: .leading, spacing: 15) {
                Text("1. tap begin and state three things about yourself")
                Text("2. two statements should be true, one should be false")
                Text("3. speak clearly and naturally")
                Text("4. tap again when finished")
                Text("5. swipe cards to analyze each statement")
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

    // MARK: 5. Summary Card
    private var summaryCard: some View {
            CardView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("final analysis")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#00FF00"))

                        if let response = service.response {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("accuracy")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Spacer()
                                    Text(String(format: "%.0f%%", response.finalConfidenceScore * 100))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(Color(hex: "#00FF00"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("analysis")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Text(response.guessJustification)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                }
                                .foregroundColor(Color(hex: "#00FF00"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("insight")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    Text(response.responseMessage)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(nil)
                                }
                                .foregroundColor(Color(hex: "#00FF00"))

                                Spacer(minLength: 20)

                                Button(action: service.resetSwipes) {
                                    Text("analyze again")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(hex: "#00FF00"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "#00FF00"), lineWidth: 1)
                                        )
                                }

                                Button(action: { step += 1 }) {
                                    Text("continue >>")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "#00FF00"))
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Text("no data available")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "#00FF00"))
                        }
                    }
                    .padding()
                }
            }
            .transition(.opacity)
        }
        // MARK: 6. Helper Functions
        private func index(of statement: StatementAnalysis) -> Int {
            service.statements.firstIndex(where: { $0.id == statement.id }) ?? 0
        }
    }

    // MARK: 7. View Extension for Stacking Effect
    extension View {
        func stacked(at position: Int, in total: Int) -> some View {
            let offset = Double(total - position) * 10
            return self.offset(CGSize(width: 0, height: offset))
        }
    }

    // MARK: 8. Preview Provider
    struct TruthLieGameView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                TruthLieGameView(step: .constant(6))
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: 9. Animation Extension
    extension Animation {
        static var cardSpring: Animation {
            .spring(response: 0.4, dampingFraction: 0.7)
        }
    }
