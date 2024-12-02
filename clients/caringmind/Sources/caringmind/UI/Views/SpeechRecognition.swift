import SwiftUI
import Speech
import ReSwift

// MARK: - Actions
enum SpeechAction: Action {
    case startRecording
    case stopRecording
    case updateTranscript(String)
    case setError(String?)
}

// MARK: - State
struct SpeechState {
    var transcript: String = ""
    var isRecording: Bool = false
    var errorMessage: String?
}

// MARK: - Reducer
func speechReducer(action: Action, state: SpeechState?) -> SpeechState {
    var state = state ?? SpeechState()

    guard let action = action as? SpeechAction else { return state }

    switch action {
    case .startRecording:
        state.isRecording = true
        state.errorMessage = nil
        return state

    case .stopRecording:
        state.isRecording = false
        return state

    case let .updateTranscript(text):
        state.transcript = text
        return state

    case let .setError(message):
        state.errorMessage = message
        return state
    }
}

// MARK: - View
struct SpeechRecognitionView: View {
    @StateObject private var speechManager = SpeechManager()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            ScrollView {
                Text(speechManager.transcript)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Button(action: {
                if speechManager.isRecording {
                    speechManager.stopRecording()
                } else {
                    speechManager.startRecording()
                }
            }) {
                HStack {
                    Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                    Text(speechManager.isRecording ? "Stop Recording" : "Start Recording")
                }
                .padding()
                .background(speechManager.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .alert(isPresented: Binding(
            get: { speechManager.errorMessage != nil },
            set: { if !$0 { speechManager.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(speechManager.errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Speech Manager
class SpeechManager: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func startRecording() {
        guard !isRecording else { return }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    do {
                        try self.startRecordingSession()
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                case .denied:
                    self.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition not yet authorized"
                @unknown default:
                    self.errorMessage = "Unknown authorization status"
                }
            }
        }
    }

    private func startRecordingSession() throws {
        // Reset any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

#if os(iOS)
        // Configure audio session
        try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
#endif

        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine and recognition task
        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.stopRecording()
                self.errorMessage = error.localizedDescription
                return
            }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false

#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
#endif
    }
}

#Preview {
    SpeechRecognitionView()
        .environmentObject(AppState())
}
