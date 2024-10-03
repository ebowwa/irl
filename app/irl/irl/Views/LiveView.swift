//  LiveView.swift
//  irl
//
//  Created by Elijah Arbee on 10/1/24.

import SwiftUI

// Wrapper struct to make String identifiable
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

struct LiveView: View {
    @State private var selectedWord: String? = nil
    @State private var selectedSentence: String? = nil
    @State private var activeConnection: ConnectionType? = nil

    // Chat messages with metadata
    let chatData = [
        (speaker: "John Doe", message: "2 PM works. I’ll see you in the conference room.", timestamp: "10:27 AM"),
        (speaker: "Jane Smith", message: "Sounds good! Let’s aim for 2 PM?", timestamp: "10:26 AM"),
        (speaker: "John Doe", message: "I thought so too. Let’s meet this afternoon to go through it.", timestamp: "10:25 AM"),
        (speaker: "Jane Smith", message: "Yeah, I looked it over this morning. Some sections need updates.", timestamp: "10:23 AM"),
        (speaker: "John Doe", message: "Hey Jane, did you check out the new report?", timestamp: "10:21 AM")
    ]

    enum ConnectionType {
        case ble, wifi, other
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ConnectionStatusView(activeConnection: $activeConnection)
                        .padding(.leading, 20)

                    // Chat message display with TextFlowView
                    ForEach(chatData, id: \.message) { message in
                        MessageFlowView(message: message.message, timestamp: message.timestamp, speaker: message.speaker, selectedWord: $selectedWord, selectedSentence: $selectedSentence)
                            .padding()
                    }

                    Spacer()
                }
            }

            // Word analysis pop-up
            if let selectedWord = selectedWord {
                WordAnalysisPopup(word: selectedWord) {
                    self.selectedWord = nil
                }
            }

            // Sentence analysis pop-up
            if let selectedSentence = selectedSentence {
                SentenceAnalysisPopup(sentence: selectedSentence) {
                    self.selectedSentence = nil
                }
            }
        }
        .onAppear {
            simulateConnectionStates()
        }
        .background(Color.clear)
    }

    // Simulate connection state changes
    private func simulateConnectionStates() {
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
}

// Message display view with text flow and interactions
struct MessageFlowView: View {
    let message: String
    let timestamp: String
    let speaker: String
    @Binding var selectedWord: String?
    @Binding var selectedSentence: String?

    @State private var isPlaying = false
    @State private var elapsedTime: Double = 0.0
    @State private var totalDuration: Double = 120.0
    @State private var showLanguageDropdown = false
    @State private var selectedLanguage: String = "English"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WaveformVisualizationView(selectedSentence: selectedSentence)
                .frame(height: 60)
                .padding(.bottom, 8)

            HStack {
                Text(timestamp)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Text("Speaker: \(speaker)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Spacer()

                LanguageDropdown(showDropdown: $showLanguageDropdown, selectedLanguage: $selectedLanguage)

                PlayPauseButton(isPlaying: $isPlaying)
            }

            AudioProgressBar(elapsedTime: elapsedTime, totalDuration: totalDuration)

            InteractiveMessageFlow(sentence: message, selectedWord: $selectedWord, selectedSentence: $selectedSentence)
        }
        .padding()
    }
}

// Language selection dropdown
struct LanguageDropdown: View {
    @Binding var showDropdown: Bool
    @Binding var selectedLanguage: String

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showDropdown.toggle()
            }) {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(selectedLanguage != "English" ? .green : .gray)
            }
            .padding(.trailing, 8)

            if showDropdown {
                Menu {
                    ForEach(["English", "Spanish", "French", "German"], id: \.self) { language in
                        Button(language) {
                            selectedLanguage = language
                            showDropdown = false
                        }
                    }
                } label: {
                    Text("Language: \(selectedLanguage)")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .background(Color.white)
                .cornerRadius(8)
            }
        }
    }
}

// Play/Pause button for message playback
struct PlayPauseButton: View {
    @Binding var isPlaying: Bool

    var body: some View {
        Button(action: {
            isPlaying.toggle()
        }) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.blue)
        }
    }
}

// Progress bar for message playback
struct AudioProgressBar: View {
    let elapsedTime: Double
    let totalDuration: Double

    var body: some View {
        HStack {
            Text(formatTime(elapsedTime))
                .font(.caption)
                .foregroundColor(.gray)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: CGFloat(elapsedTime / totalDuration) * 150, height: 4)
            }
            .frame(maxWidth: 150)

            Text(formatTime(totalDuration))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Visual representation of waveform for selected message
struct WaveformVisualizationView: View {
    let selectedSentence: String?

    @State private var pulse = false
    @State private var gradientShift = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.5))
                .frame(height: 50)
                .scaleEffect(pulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: pulse)
                .onAppear {
                    pulseEffect()
                }

            if selectedSentence != nil {
                WaveformGradientEffect(gradientShift: $gradientShift)
            }
        }
        .shadow(radius: 5)
        .padding()
    }

    private func pulseEffect() {
        self.pulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.pulse = false
        }
    }
}

// Reusable gradient effect for waveform
struct WaveformGradientEffect: View {
    @Binding var gradientShift: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
                               startPoint: gradientShift ? .leading : .trailing,
                               endPoint: gradientShift ? .trailing : .leading)
            )
            .frame(width: 150, height: 40)
            .animation(Animation.linear(duration: 2), value: gradientShift)
            .onAppear {
                self.gradientShift = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.gradientShift = false
                }
            }
    }
}

// Word-level analysis popup
struct WordAnalysisPopup: View {
    let word: String
    var onClose: () -> Void

    var body: some View {
        VStack {
            Text("Word Analysis for '\(word)'")
                .font(.headline)
                .padding(.top, 8)

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

// Sentence-level analysis popup
struct SentenceAnalysisPopup: View {
    let sentence: String
    var onClose: () -> Void

    var body: some View {
        VStack {
            Text("Sentence Analysis")
                .font(.headline)
                .padding(.top, 8)

            Text(sentence)
                .padding(.horizontal, 12)

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

// Sentence text with word selection capability
struct InteractiveMessageFlow: View {
    let sentence: String
    @Binding var selectedWord: String?
    @Binding var selectedSentence: String?

    var body: some View {
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
}

// Flow layout to handle word wrapping dynamically
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

struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView()
    }
}
