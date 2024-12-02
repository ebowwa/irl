import Foundation
import ReSwift
import GoogleSignIn

// MARK: - App State
struct AppState: Equatable {
    var auth = AuthState()
    var onboarding = OnboardingState()
    var navigation = NavigationState()
    var audio = AudioState()

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        lhs.auth == rhs.auth &&
        lhs.onboarding == rhs.onboarding &&
        lhs.navigation == rhs.navigation &&
        lhs.audio == rhs.audio
    }

    static var initialState: AppState {
        AppState()
    }
}

// MARK: - Auth State
struct AuthState: Equatable {
    var isAuthenticated = false
    var currentUser: GIDGoogleUser?
    var error: Error?

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        lhs.isAuthenticated == rhs.isAuthenticated &&
        lhs.currentUser?.userID == rhs.currentUser?.userID &&
        lhs.error?.localizedDescription == rhs.error?.localizedDescription
    }
}

// MARK: - Onboarding State
struct OnboardingState: Equatable {
    var currentStep: OnboardingStep = .welcome
    var isLoading = false
    var name = ""
    var age: Int?
    var isComplete = false
}

enum OnboardingStep: Equatable {
    case welcome
    case nameInput
    case ageInput
    case complete
}

// MARK: - Navigation State
struct NavigationState: Equatable {
    var currentRoute: Route = .splash
    var isLoading = false
    var error: Error?

    static func == (lhs: NavigationState, rhs: NavigationState) -> Bool {
        lhs.currentRoute == rhs.currentRoute &&
        lhs.isLoading == rhs.isLoading &&
        lhs.error?.localizedDescription == rhs.error?.localizedDescription
    }
}

enum Route: Equatable {
    case splash
    case onboarding
    case home
    case settings
}

// MARK: - Audio State
struct AudioState: Equatable {
    var isRecording = false
    var recordings: [Recording] = []
    var error: Error?

    static func == (lhs: AudioState, rhs: AudioState) -> Bool {
        lhs.isRecording == rhs.isRecording &&
        lhs.recordings == rhs.recordings &&
        lhs.error?.localizedDescription == rhs.error?.localizedDescription
    }
}

// MARK: - Recording Model
struct Recording: Equatable, Identifiable {
    let id: String
    let url: URL
    let timestamp: Date
    var duration: TimeInterval
    var title: String

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id &&
        lhs.url == rhs.url &&
        lhs.timestamp == rhs.timestamp &&
        lhs.duration == rhs.duration &&
        lhs.title == rhs.title
    }
}

// MARK: - Store
let mainStore = Store<AppState>(
    reducer: appReducer,
    state: AppState.initialState,
    middleware: [loggerMiddleware]
)
