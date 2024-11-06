//
//  TruthLieGameView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/5/24.
//
// TruthGameView.swift
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
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
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

struct AnalysisView: View {
    // 3.1. Observed service to manage data and logic.
    @StateObject private var service = AnalysisService()
    
    var body: some View {
        VStack {
            // 3.2. Recording Container
            recordingContainer
                .padding()
            
            Divider()
            
            // 3.3. Swipeable Cards Area
            ZStack {
                // 3.4. Show Summary Card if all statements have been swiped.
                if service.showSummary {
                    summaryCard
                        .transition(.opacity)
                } else {
                    // 3.5. If there are no more statements to swipe, display a placeholder.
                    if service.statements.filter { !service.swipedStatements.contains($0.id) }.isEmpty && service.response != nil {
                        Text("No more statements")
                            .font(.title)
                            .foregroundColor(.secondary)
                    } else {
                        // 3.6. Use ZStack to layer cards on top of each other.
                        ForEach(service.statements) { statement in
                            // Only display cards that haven't been swiped.
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
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("AI Analysis Results")
        .alert(item: $service.recordingError) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: 4. Recording Container
    
    /// 4.1. A container that provides recording controls.
    private var recordingContainer: some View {
        VStack(spacing: 20) {
            Text("Record Your Statements")
                .font(.headline)
            
            if service.isRecording {
                Text("Recording in progress...")
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 40) {
                // Record Button
                Button(action: {
                    if service.isRecording {
                        service.stopRecording()
                    } else {
                        service.startRecording()
                    }
                }) {
                    Image(systemName: service.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(service.isRecording ? .red : .blue)
                }
                
                // Play Button
                Button(action: {
                    if service.isPlaying {
                        service.stopPlaying()
                    } else {
                        service.playRecording()
                    }
                }) {
                    Image(systemName: service.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                
                // Upload Button
                Button(action: {
                    service.uploadRecording()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.purple)
                }
                .disabled(service.recordedURL == nil || service.isRecording)
            }
            
            // Display upload status or response
            if let response = service.response {
                Text("Upload Successful! Swipe the analyzed statements below.")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: 5. Summary Card
    
    /// 5.1. The summary analysis card displayed after all statements have been swiped.
    private var summaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                
                if let response = service.response {
                    Group {
                        Text("**Final Confidence Score:** \(String(format: "%.2f", response.finalConfidenceScore))")
                        Text("**Guess Justification:** \(response.guessJustification)")
                        Text("**Response Message:** \(response.responseMessage)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    // 5.2. Reset Button to allow users to revisit the cards.
                    Button(action: service.resetSwipes) {
                        Text("Reset")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
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
    
    /// 6.1. Calculates the index of a statement within the statements array.
    /// - Parameter statement: The statement to find.
    /// - Returns: The index of the statement or 0 if not found.
    private func index(of statement: StatementAnalysis) -> Int {
        guard let idx = service.statements.firstIndex(where: { $0.id == statement.id }) else {
            return 0
        }
        return idx
    }
}

// MARK: 7. View Extension for Stacking Effect

extension View {
    /// 7.1. Applies a stacking offset to simulate a deck of cards.
    /// - Parameters:
    ///   - position: The position of the card in the stack.
    ///   - total: The total number of cards.
    /// - Returns: A view with an applied offset.
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position) * 10
        return self.offset(CGSize(width: 0, height: offset))
    }
}

// MARK: 8. Preview

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalysisView()
        }
    }
}
