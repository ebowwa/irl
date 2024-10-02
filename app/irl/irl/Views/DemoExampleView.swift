//
//  IRLDemoView.swift
//  irl
//
//  Created by Elijah Arbee on 10/1/24.
//
//
//  IRLDemoView.swift
//  irl
//
//  Created by Elijah Arbee on 10/1/24.
//
//
//  IRLDemoView.swift
//  irl
//
//  Created by Elijah Arbee on 10/1/24.
//
import SwiftUI

// Wrapper struct to make String identifiable
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

import SwiftUI

struct DemoExampleView: View {
    @State private var selectedWord: String? = nil
    @State private var selectedSentence: String? = nil
    @State private var activeConnection: ConnectionType? = nil
    
    let sentence = "This is a sample sentence to demonstrate tappable words in SwiftUI."
    let timestamp = "10:21 AM"
    let speaker = "John Doe"
    
    enum ConnectionType {
        case ble, wifi, other
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // New connection status shape in top-left corner (scrolls with content)
                    VStack {
                        if let connection = activeConnection {
                            switch connection {
                            case .ble:
                                Text("🔗") // BLE connection emoji
                            case .wifi:
                                Text("📶") // WiFi connection emoji
                            case .other:
                                Text("🔌") // Other connection emoji
                            }
                        } else {
                            Text("No connection")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.leading, 20) // Position on the left side
                    
                    // The main content (text flow view)
                    TextFlowView(sentence: sentence, timestamp: timestamp, speaker: speaker, selectedWord: $selectedWord, selectedSentence: $selectedSentence)
                        .padding()
                    
                    Spacer() // Keep the spacer to maintain layout flexibility
                }
            }
            
            // Word analysis pop-up
            if let selectedWord = selectedWord {
                WordPopup(word: selectedWord) {
                    self.selectedWord = nil // Close the popup
                }
            }
            
            // Sentence analysis pop-up
            if let selectedSentence = selectedSentence {
                SentencePopup(sentence: selectedSentence) {
                    self.selectedSentence = nil // Close the popup
                }
            }
        }
        .onAppear {
            // Simulate connection type changes for testing purposes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                activeConnection = .wifi
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                activeConnection = .ble
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                activeConnection = .other
            }
        }
        .background(Color.clear) // Ensure the background doesn't affect the scrolling
    }
}


struct TextFlowView: View {
    let sentence: String
    let timestamp: String
    let speaker: String
    @Binding var selectedWord: String?
    @Binding var selectedSentence: String?
    
    @State private var isPlaying = false
    @State private var elapsedTime: Double = 0.0 // Elapsed time for the progress bar
    @State private var totalDuration: Double = 120.0 // Example total duration in seconds

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // First, display the waveform above the transcript
            WaveformView(selectedSentence: selectedSentence)
                .frame(height: 60) // Adjust size as needed
                .padding(.bottom, 8)

            // Now, display the bold timestamp and speaker information
            HStack {
                Text(timestamp)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Speaker: \(speaker)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()

                // Play/pause button
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
            }

            // Timeline with elapsed time and total duration
            HStack {
                // Elapsed time
                Text(formatTime(elapsedTime))
                    .font(.caption)
                    .foregroundColor(.gray)

                // Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: CGFloat(elapsedTime / totalDuration) * 150, height: 4) // Adjust width accordingly
                }
                .frame(maxWidth: 150) // Fixed width for the timeline

                // Total duration
                Text(formatTime(totalDuration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // The tappable words/transcript
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedSentence = sentence
                    }

                FlowLayout(mode: .scrollable, items: sentence.split(separator: " ").map { String($0) }, itemSpacing: 4) { word in
                    Text(word + " ")
                        .font(.system(size: 18))
                        .foregroundColor(self.selectedWord == word ? Color.blue : Color.primary)
                        .background(self.selectedWord == word ? Color.yellow : Color.clear)
                        .onTapGesture {
                            self.selectedWord = word
                        }
                }
            }
        }
        .padding()
    }

    // Helper function to format time
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}



struct WaveformView: View {
    let selectedSentence: String?
    
    // State variables for animation
    @State private var pulse = false
    @State private var gradientShift = false
    
    var body: some View {
        ZStack {
            // Background waveform rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.5))
                .frame(height: 50)
                // Animation only when view appears or is triggered by an event
                .scaleEffect(pulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: pulse)
                .onAppear {
                    self.pulse = true // Trigger animation once at screen load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.pulse = false // Stop the animation after it runs once
                    }
                }

            if selectedSentence != nil {
                // Highlighted sentence rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
                                       startPoint: gradientShift ? .leading : .trailing,
                                       endPoint: gradientShift ? .trailing : .leading)
                    )
                    .frame(width: 150, height: 40)
                    // Shift the gradient smoothly, but stop auto-reversing
                    .animation(Animation.linear(duration: 2), value: gradientShift)
                    .onAppear {
                        self.gradientShift = true // Trigger gradient shift
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.gradientShift = false // Stop gradient shift after one cycle
                        }
                    }
            }
        }
        .shadow(radius: 5)
        .padding()
    }
}



// Word popup widget
struct WordPopup: View {
    let word: String
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            Text("Word Analysis for '\(word)'")
                .font(.headline)
                .padding(.top, 8)
            
            // Placeholder for word-level analysis content
            Text("Pitch: 120 Hz\nIntensity: Medium\nAI Analysis: Neutral")
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
            
            Button(action: onClose) {
                Text("Close")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
        }
        .frame(width: 250, height: 150)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3)
    }
}

// Sentence popup widget
struct SentencePopup: View {
    let sentence: String
    var onClose: () -> Void
    
    var body: some View {
        VStack {
            Text("Sentence Analysis")
                .font(.headline)
                .padding(.top, 8)
            
            Text(sentence)
                .padding(.horizontal, 12)
            
            // Placeholder for sentence-level analysis content
            Text("Overall pitch: High\nIntensity: Strong\nAI Sentiment: Positive")
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
            
            Button(action: onClose) {
                Text("Close")
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
        }
        .frame(width: 300, height: 200)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    }
}

// FlowLayout implementation
enum FlowLayoutMode {
    case scrollable, vstack
}

struct FlowLayout<Item: Hashable, Content: View>: View {
    let mode: FlowLayoutMode
    let items: [Item]
    let itemSpacing: CGFloat
    let content: (Item) -> Content

    init(mode: FlowLayoutMode,
         items: [Item],
         itemSpacing: CGFloat = 4,
         @ViewBuilder content: @escaping (Item) -> Content) {
        self.mode = mode
        self.items = items
        self.itemSpacing = itemSpacing
        self.content = content
    }

    var body: some View {
        generateContent()
    }

    private func generateContent() -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(self.items, id: \.self) { item in
                    self.content(item)
                        .padding(.horizontal, self.itemSpacing)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == self.items.last {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { d in
                            let result = height
                            if item == self.items.last {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
    }
}

struct DemoExampleView_Previews: PreviewProvider {
    static var previews: some View {
        DemoExampleView()
    }
}
