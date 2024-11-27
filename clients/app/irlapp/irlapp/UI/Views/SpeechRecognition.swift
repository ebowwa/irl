import ComposableArchitecture
import Speech
import SwiftUI

private let readMe = """
  This application demonstrates how to work with a complex dependency in the Composable \
  Architecture. It uses the SFSpeechRecognizer API from the Speech framework to listen to audio \
  on the device and live-transcribe it to the UI.
  """

@Reducer
struct SpeechRecognition {
  @ObservableState
  struct State: Equatable {
    @Presents var alert: AlertState<Action.Alert>?
    var isRecording = false
    var transcribedText = ""
    
    // VoiceAnalytics properties
    var averagePauseDuration: TimeInterval?
    var speakingRate: Double?
    var jitter: Double?
    var pitch: Double?
    var shimmer: Double?
    var voicing: Double?
  }

  enum Action {
    case alert(PresentationAction<Alert>)
    case recordButtonTapped
    case speech(Result<String, any Error>)
    case speechRecognizerAuthorizationStatusResponse(SFSpeechRecognizerAuthorizationStatus)
    
    // New actions for VoiceAnalytics and Metadata
    case updateVoiceAnalytics(SpeechRecognitionMetadata)
    
    enum Alert: Equatable {}
  }

  @Dependency(\.speechClient) var speechClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .alert:
        return .none

      case .recordButtonTapped:
        state.isRecording.toggle()

        guard state.isRecording
        else {
          return .run { _ in
            await self.speechClient.finishTask()
          }
        }

        return .run { send in
          let status = await self.speechClient.requestAuthorization()
          await send(.speechRecognizerAuthorizationStatusResponse(status))

          guard status == .authorized else { return }

          let request = SFSpeechAudioBufferRecognitionRequest()
          for try await result in await self.speechClient.startTask(request) {
            await send(
              .speech(.success(result.bestTranscription.formattedString)),
              animation: .linear
            )
            
            // Dispatch action to update VoiceAnalytics
            if let metadata = result.speechRecognitionMetadata {
              await send(.updateVoiceAnalytics(metadata))
            }
          }
        } catch: { error, send in
          await send(.speech(.failure(error)))
        }

      case .speech(.failure(SpeechClient.Failure.couldntConfigureAudioSession)),
           .speech(.failure(SpeechClient.Failure.couldntStartAudioEngine)):
        state.alert = AlertState { TextState("Problem with audio device. Please try again.") }
        return .none

      case .speech(.failure):
        state.alert = AlertState {
          TextState("An error occurred while transcribing. Please try again.")
        }
        return .none

      case let .speech(.success(transcribedText)):
        state.transcribedText = transcribedText
        return .none

      case let .speechRecognizerAuthorizationStatusResponse(status):
        state.isRecording = status == .authorized

        switch status {
        case .authorized:
          return .none

        case .denied:
          state.alert = AlertState {
            TextState(
              """
              You denied access to speech recognition. This app needs access to transcribe your \
              speech.
              """
            )
          }
          return .none

        case .notDetermined:
          return .none

        case .restricted:
          state.alert = AlertState { TextState("Your device does not allow speech recognition.") }
          return .none

        @unknown default:
          return .none
        }

      // Handle VoiceAnalytics updates
      case let .updateVoiceAnalytics(metadata):
        state.averagePauseDuration = metadata.averagePauseDuration
        state.speakingRate = metadata.speakingRate
        if let voiceAnalytics = metadata.voiceAnalytics {
          state.jitter = voiceAnalytics.jitter.acousticFeatureValuePerFrame.last
          state.pitch = voiceAnalytics.pitch.acousticFeatureValuePerFrame.last
          state.shimmer = voiceAnalytics.shimmer.acousticFeatureValuePerFrame.last
          state.voicing = voiceAnalytics.voicing.acousticFeatureValuePerFrame.last
        }
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

struct SpeechRecognitionView: View {
  @Bindable var store: StoreOf<SpeechRecognition>

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text(readMe)
          .padding(.bottom, 32)
      }

      ScrollView {
        ScrollViewReader { proxy in
          Text(store.transcribedText)
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

      Spacer()

      // Display VoiceAnalytics
      VStack(alignment: .leading, spacing: 8) {
        if let speakingRate = store.speakingRate {
          Text("Speaking Rate: \(String(format: "%.2f", speakingRate))")
        }
        if let averagePause = store.averagePauseDuration {
          Text("Average Pause Duration: \(String(format: "%.2f", averagePause))s")
        }
        if let jitter = store.jitter {
          Text("Jitter: \(String(format: "%.2f", jitter))")
        }
        if let pitch = store.pitch {
          Text("Pitch: \(String(format: "%.2f", pitch)) Hz")
        }
        if let shimmer = store.shimmer {
          Text("Shimmer: \(String(format: "%.2f", shimmer))")
        }
        if let voicing = store.voicing {
          Text("Voicing: \(String(format: "%.2f", voicing))")
        }
      }
      .font(.subheadline)
      .padding(.bottom, 16)

      Button {
        store.send(.recordButtonTapped)
      } label: {
        HStack {
          Image(
            systemName: store.isRecording
              ? "stop.circle.fill" : "arrowtriangle.right.circle.fill"
          )
          .font(.title)
          Text(store.isRecording ? "Stop Recording" : "Start Recording")
        }
        .foregroundColor(.white)
        .padding()
        .background(store.isRecording ? Color.red : .green)
        .cornerRadius(16)
      }
    }
    .padding()
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview {
  SpeechRecognitionView(
    store: Store(initialState: SpeechRecognition.State(transcribedText: "Test test 123")) {
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
