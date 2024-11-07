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

struct TruthLieGameView: View {
    // 3.1. Add a binding to the step variable
    @Binding var step: Int
    // 3.2. Observed service to manage data and logic.
    @StateObject private var service = AnalysisService()

    var body: some View {
        VStack {
            // 3.3. Recording Container
            recordingContainer
                .padding()

            Divider()

            // 3.4. Swipeable Cards Area
            ZStack {
                // 3.5. Show Summary Card if all statements have been swiped.
                if service.showSummary {
                    summaryCard
                        .transition(.opacity)
                } else {
                    // 3.6. If there are no more statements to swipe, display a placeholder.
                    if service.statements.filter { !service.swipedStatements.contains($0.id) }.isEmpty && service.response != nil {
                        Text("No more statements")
                            .font(.title)
                            .foregroundColor(.secondary)
                    } else {
                        // 3.7. Use ZStack to layer cards on top of each other.
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
        .navigationTitle("AI Analysis Results")
        .alert(item: $service.recordingError) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: 4. Recording Container

    /// 4.1. A container for the "Two Truths and a Lie" game with a single "Get Started" button.
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(service.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }

            if let response = service.response {
                Text("Upload Successful! Check your statements below.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.clear)
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

                    // 5.3. Next Button to proceed to the next onboarding step
                    Button(action: {
                        step += 1
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
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

struct TruthLieGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TruthLieGameView(step: .constant(6))
        }
    }
}
