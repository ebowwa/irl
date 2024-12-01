import SwiftUI
import ComposableArchitecture
import Speech

struct SpeechRecognition: Reducer {
    struct State: Equatable {
        var transcript: String = ""
        var isRecording: Bool = false
        var errorMessage: String?
        @PresentationState var alert: AlertState<Action.Alert>?
    }
    
    enum Action: Equatable {
        case startRecording
        case stopRecording
        case updateTranscript(String)
        case setError(String?)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case dismiss
        }
    }
    
    @Dependency(\.speechClient) var speechClient
    private let audioEngine = AVAudioEngine()
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startRecording:
                state.isRecording = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        #if os(iOS)
                        try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
                        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                        #endif
                        
                        let status = await speechClient.requestAuthorization()
                        guard status == .authorized else {
                            await send(.setError("Speech recognition not authorized"))
                            await send(.stopRecording)
                            return
                        }
                        
                        let request = SFSpeechAudioBufferRecognitionRequest()
                        request.shouldReportPartialResults = true
                        
                        let result = try await speechClient.startTask(audioEngine, request)
                        await send(.updateTranscript(result.bestTranscription.formattedString))
                    } catch {
                        if let failure = error as? SpeechClient.Failure {
                            await send(.setError(failure.errorDescription))
                        } else {
                            await send(.setError(error.localizedDescription))
                        }
                        await send(.stopRecording)
                    }
                }
                
            case .stopRecording:
                state.isRecording = false
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
                
                return .run { _ in
                    await speechClient.finishTask()
                }
                
            case let .updateTranscript(text):
                state.transcript = text
                return .none
                
            case let .setError(message):
                state.errorMessage = message
                if let message = message {
                    state.alert = AlertState {
                        TextState("Error")
                    } actions: {
                        ButtonState(action: .dismiss) {
                            TextState("OK")
                        }
                    } message: {
                        TextState(message)
                    }
                }
                return .none
                
            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct SpeechRecognitionView: View {
    let store: StoreOf<SpeechRecognition>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                ScrollView {
                    Text(viewStore.transcript)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                Button(action: {
                    if viewStore.isRecording {
                        viewStore.send(.stopRecording)
                    } else {
                        viewStore.send(.startRecording)
                    }
                }) {
                    HStack {
                        Image(systemName: viewStore.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24))
                        Text(viewStore.isRecording ? "Stop Recording" : "Start Recording")
                    }
                    .padding()
                    .background(viewStore.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
        }
    }
}

#Preview {
  SpeechRecognitionView(
    store: Store(initialState: SpeechRecognition.State(transcript: "Test test 123")) {
      SpeechRecognition()
    }
  )
}
/**
 import ComposableArchitecture
 import SwiftUI

 struct SpeechRecognitionApp: App {
   var body: some Scene {
     WindowGroup {
       SpeechRecognitionView(
         store: Store(initialState: SpeechRecognition.State()) {
           SpeechRecognition()._printChanges()
         }
       )
     }
   }
 }
  */
