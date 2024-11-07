//
//  TruthLieGameView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/5/24.
//
import SwiftUI

// MARK: 1. Reusable Card View

/// 1.1. A generic card view that provides a consistent style for all cards.
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
                    Color(.systemBackground)
                    // Subtle circuit pattern overlay
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            // Create subtle decorative lines
                            path.move(to: CGPoint(x: 0, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.3))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
                            
                            path.move(to: CGPoint(x: width, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.7))
                            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
                        }
                        .stroke(Color(hex: "#00FF00").opacity(0.1), lineWidth: 0.5)
                    }
                }
            )
            .cornerRadius(15)
            .shadow(color: Color(hex: "#00FF00").opacity(0.1), radius: 5, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(hex: "#00FF00").opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: 350, maxHeight: 500)
    }
}

// MARK: 2. Swipeable Card View

/// 2.1. Represents a single swipeable card with gesture handling.
struct SwipeableCardView: View {
    let statement: StatementAnalysis
    let onSwipe: (_ direction: AnalysisService.SwipeDirection, _ statement: StatementAnalysis) -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var glowIntensity: Double = 0

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                // Title indicating if the statement is a truth or a lie
                if statement.isTruth {
                    HStack {
                        Text("Truth Detected")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Text("Detected Lie")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Image(systemName: "wand.and.rays")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }

                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.2))

                // Display only the statement text
                Text("**Statement:** \(statement.statement)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

    var body: some View {
        VStack {
            recordingContainer
                .padding()

            Divider()
                .background(Color(hex: "#00FF00").opacity(0.2))

            ZStack {
                if service.showSummary {
                    summaryCard
                        .transition(.opacity)
                } else {
                    if service.statements.filter { !service.swipedStatements.contains($0.id) }.isEmpty && service.response != nil {
                        Text("No more statements")
                            .font(.title)
                            .foregroundColor(.secondary)
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
        .navigationTitle("AI Analysis Results")
        .alert(item: $service.recordingError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: 4. Recording Container

    private var recordingContainer: some View {
        VStack(spacing: 20) {
            Text("Two Truths and a Lie")
                .font(.headline)
                .foregroundColor(.primary)

            Button(action: {
                if service.isRecording {
                    service.stopRecording()
                    service.uploadRecording()
                } else {
                    service.startRecording()
                }
            }) {
                Text(service.isRecording ? "Stop & Upload" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        service.isRecording ? Color.red : Color(hex: "#00FF00")
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#00FF00").opacity(0.2), lineWidth: 1)
                    )
            }

            if let response = service.response {
                Text("Upload Successful! Check your statements below.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: 5. Summary Card

    private var summaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)

                Divider()
                    .background(Color(hex: "#00FF00").opacity(0.2))

                if let response = service.response {
                    Group {
                        Text("**Final Confidence Score:** \(String(format: "%.2f", response.finalConfidenceScore))")
                        Text("**Guess Justification:** \(response.guessJustification)")
                        Text("**Response Message:** \(response.responseMessage)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Button(action: service.resetSwipes) {
                        Text("Reset")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#00FF00"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#00FF00").opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)

                    Button(action: {
                        step += 1
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#00FF00"))
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                } else {
                    Text("No summary available.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .transition(.opacity)
    }

    // MARK: 6. Helper Functions

    private func index(of statement: StatementAnalysis) -> Int {
        guard let idx = service.statements.firstIndex(where: { $0.id == statement.id }) else {
            return 0
        }
        return idx
    }
}

// MARK: 7. View Extension for Stacking Effect

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position) * 10
        return self.offset(CGSize(width: 0, height: offset))
    }
}

// MARK: 8. Color Extension
/**
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
*/
// MARK: 9. Preview

struct TruthLieGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TruthLieGameView(step: .constant(6))
        }
    }
}
