import Foundation
import GoogleSignIn

// MARK: - Root Action
enum Action {
    case auth(AuthAction)
    case onboarding(OnboardingAction)
    case navigation(NavigationAction)
    case audio(AudioAction)
}

// MARK: - Authentication Actions
enum AuthAction {
    case signIn(GIDGoogleUser)
    case signInSuccess(GIDGoogleUser)
    case signInFailure(Error)
    case signOut
}

// MARK: - Onboarding Actions
enum OnboardingAction {
    case next
    case previous
    case setName(String)
    case setAge(Int)
    case complete
}

// MARK: - Navigation Actions
enum NavigationAction {
    case navigate(Route)
    case setLoading(Bool)
}

// MARK: - Audio Actions
enum AudioAction {
    case startRecording
    case stopRecording
    case recordingSuccess(URL)
    case recordingError(Error)
    case deleteRecording(String)
}

// MARK: - Navigation Routes
enum Route {
    case splash
    case onboarding
    case home
    case settings
    case profile
    case recording
}

// MARK: - Action Extensions
extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        switch (lhs, rhs) {
        case (.auth(let lhsAction), .auth(let rhsAction)):
            return lhsAction == rhsAction
        case (.onboarding(let lhsAction), .onboarding(let rhsAction)):
            return lhsAction == rhsAction
        case (.navigation(let lhsAction), .navigation(let rhsAction)):
            return lhsAction == rhsAction
        case (.audio(let lhsAction), .audio(let rhsAction)):
            return lhsAction == rhsAction
        default:
            return false
        }
    }
}

extension AuthAction: Equatable {
    static func == (lhs: AuthAction, rhs: AuthAction) -> Bool {
        switch (lhs, rhs) {
        case (.signIn(let lhsUser), .signIn(let rhsUser)):
            return lhsUser.userID == rhsUser.userID
        case (.signInSuccess(let lhsUser), .signInSuccess(let rhsUser)):
            return lhsUser.userID == rhsUser.userID
        case (.signInFailure(let lhsError), .signInFailure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.signOut, .signOut):
            return true
        default:
            return false
        }
    }
}

extension OnboardingAction: Equatable {}
extension NavigationAction: Equatable {}
extension AudioAction: Equatable {
    static func == (lhs: AudioAction, rhs: AudioAction) -> Bool {
        switch (lhs, rhs) {
        case (.startRecording, .startRecording):
            return true
        case (.stopRecording, .stopRecording):
            return true
        case (.recordingSuccess(let lhsURL), .recordingSuccess(let rhsURL)):
            return lhsURL == rhsURL
        case (.recordingError(let lhsError), .recordingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.deleteRecording(let lhsId), .deleteRecording(let rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

extension Route: Equatable {}
