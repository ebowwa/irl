import Foundation
import ReSwift

// MARK: - App Reducer
func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState.initialState
    
    switch action {
    case .auth(let authAction):
        state.auth = authReducer(action: authAction, state: state.auth)
    case .onboarding(let onboardingAction):
        state.onboarding = onboardingReducer(action: onboardingAction, state: state.onboarding)
    case .navigation(let navigationAction):
        state.navigation = navigationReducer(action: navigationAction, state: state.navigation)
    case .audio(let audioAction):
        state.audio = audioReducer(action: audioAction, state: state.audio)
    }
    
    return state
}

// MARK: - Auth Reducer
func authReducer(action: AuthAction, state: AuthState) -> AuthState {
    var state = state
    
    switch action {
    case .signIn(let user):
        state.isAuthenticated = true
        state.currentUser = user
        state.error = nil
        
    case .signInSuccess(let user):
        state.isAuthenticated = true
        state.currentUser = user
        state.error = nil
        
    case .signInFailure(let error):
        state.isAuthenticated = false
        state.currentUser = nil
        state.error = error
        
    case .signOut:
        state.isAuthenticated = false
        state.currentUser = nil
        state.error = nil
    }
    
    return state
}

// MARK: - Onboarding Reducer
func onboardingReducer(action: OnboardingAction, state: OnboardingState) -> OnboardingState {
    var state = state
    
    switch action {
    case .next:
        switch state.currentStep {
        case .welcome:
            state.currentStep = .nameInput
        case .nameInput:
            state.currentStep = .ageInput
        case .ageInput:
            state.currentStep = .complete
        case .complete:
            state.isComplete = true
        }
        
    case .previous:
        switch state.currentStep {
        case .welcome:
            break
        case .nameInput:
            state.currentStep = .welcome
        case .ageInput:
            state.currentStep = .nameInput
        case .complete:
            state.currentStep = .ageInput
        }
        
    case .setName(let name):
        state.name = name
        
    case .setAge(let age):
        state.age = age
        
    case .complete:
        state.isComplete = true
    }
    
    return state
}

// MARK: - Navigation Reducer
func navigationReducer(action: NavigationAction, state: NavigationState) -> NavigationState {
    var state = state
    
    switch action {
    case .navigate(let route):
        state.currentRoute = route
        state.error = nil
        
    case .setLoading(let isLoading):
        state.isLoading = isLoading
    }
    
    return state
}

// MARK: - Audio Reducer
func audioReducer(action: AudioAction, state: AudioState) -> AudioState {
    var state = state
    
    switch action {
    case .startRecording:
        state.isRecording = true
        state.error = nil
        
    case .stopRecording:
        state.isRecording = false
        
    case .recordingSuccess(let url):
        let recording = Recording(
            id: UUID().uuidString,
            url: url,
            timestamp: Date(),
            duration: 0, // This should be calculated from the audio file
            title: "Recording \(state.recordings.count + 1)"
        )
        state.recordings.append(recording)
        state.error = nil
        
    case .recordingError(let error):
        state.isRecording = false
        state.error = error
        
    case .deleteRecording(let id):
        state.recordings.removeAll { $0.id == id }
        state.error = nil
    }
    
    return state
}
