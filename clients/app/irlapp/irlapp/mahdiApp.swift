//
//  CaringMindApp.swift
//  CaringMind
//
//  General App Description: this product is meant to listen 24/7 it uses the openaudio which allows for processing of audio from devices and storing, post requests, websocket, audio playing controls, local audio measurement, etc
// - this app should always be recording, it may be recording for local storage, for batch uploads to server, or for a live-streaming websocket
// - this functionality should not be managed by views, but can be modified, i.e., switch to websocket, send data to server, playbacks, viewing transcriptions, data, etc
//
// NOTE: this script was updated to include a google sign in which as of now does nothing, it works, the user can sign in with their google account but otherwise this feature has no other extension, moving forward location, usage metrics, drive storage can be applied through this gsignin

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI
import ReSwift

// MARK: - ReSwift State, Actions, and Reducers

// Define the AppState which holds the entire state of the application
struct AppState: StateType {
    var user: UserState
    var registration: RegistrationState
    var onboarding: OnboardingState
    var router: RouterState
    var audio: AudioState
}

// Define the UserState
struct UserState {
    var isSignedIn: Bool
    var userID: String?
    var error: String?
}

// Define the RegistrationState
struct RegistrationState {
    var isRegistered: Bool
    var deviceUUID: String?
    var error: String?
}

// Define the OnboardingState
struct OnboardingState {
    var currentStep: OnboardingStep
    var userName: String
}

// Define the RouterState
struct RouterState {
    var currentDestination: RouterDestination
}

// Define the AudioState
struct AudioState {
    var isRecording: Bool
    var audioData: [AudioData]
    // Add other audio-related properties as needed
}

// Define AudioData structure
struct AudioData {
    // Define properties for audio data
    var id: UUID
    var data: Data
    var timestamp: Date
}

// Define Actions

// User Actions
struct SignInAction: Action {
    let userID: String
}

struct SignOutAction: Action {}

struct SignInFailureAction: Action {
    let error: String
}

// Registration Actions
struct RegistrationSuccessAction: Action {
    let deviceUUID: String
}

struct RegistrationFailureAction: Action {
    let error: String
}

// Onboarding Actions
struct UpdateOnboardingStepAction: Action {
    let step: OnboardingStep
}

struct UpdateUserNameAction: Action {
    let userName: String
}

// Router Actions
struct NavigateAction: Action {
    let destination: RouterDestination
}

// Audio Actions
struct StartRecordingAction: Action {}
struct StopRecordingAction: Action {}
struct AddAudioDataAction: Action {
    let audioData: AudioData
}

// Define Reducers

func appReducer(action: Action, state: AppState?) -> AppState {
    return AppState(
        user: userReducer(action: action, state: state?.user),
        registration: registrationReducer(action: action, state: state?.registration),
        onboarding: onboardingReducer(action: action, state: state?.onboarding),
        router: routerReducer(action: action, state: state?.router),
        audio: audioReducer(action: action, state: state?.audio)
    )
}

func userReducer(action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState(isSignedIn: false, userID: nil, error: nil)
    
    switch action {
    case let action as SignInAction:
        state.isSignedIn = true
        state.userID = action.userID
        state.error = nil
    case _ as SignOutAction:
        state.isSignedIn = false
        state.userID = nil
    case let action as SignInFailureAction:
        state.error = action.error
    default:
        break
    }
    
    return state
}

func registrationReducer(action: Action, state: RegistrationState?) -> RegistrationState {
    var state = state ?? RegistrationState(isRegistered: false, deviceUUID: nil, error: nil)
    
    switch action {
    case let action as RegistrationSuccessAction:
        state.isRegistered = true
        state.deviceUUID = action.deviceUUID
        state.error = nil
    case let action as RegistrationFailureAction:
        state.isRegistered = false
        state.error = action.error
    default:
        break
    }
    
    return state
}

func onboardingReducer(action: Action, state: OnboardingState?) -> OnboardingState {
    var state = state ?? OnboardingState(currentStep: .intro, userName: "")
    
    switch action {
    case let action as UpdateOnboardingStepAction:
        state.currentStep = action.step
    case let action as UpdateUserNameAction:
        state.userName = action.userName
    default:
        break
    }
    
    return state
}

func routerReducer(action: Action, state: RouterState?) -> RouterState {
    var state = state ?? RouterState(currentDestination: .splash)
    
    switch action {
    case let action as NavigateAction:
        state.currentDestination = action.destination
    default:
        break
    }
    
    return state
}

func audioReducer(action: Action, state: AudioState?) -> AudioState {
    var state = state ?? AudioState(isRecording: false, audioData: [])
    
    switch action {
    case _ as StartRecordingAction:
        state.isRecording = true
    case _ as StopRecordingAction:
        state.isRecording = false
    case let action as AddAudioDataAction:
        state.audioData.append(action.audioData)
    default:
        break
    }
    
    return state
}

// Define Onboarding Steps
enum OnboardingStep {
    case intro
    case permissions
    case completion
}

// Initialize the ReSwift store
let mainStore = Store<AppState>(
    reducer: appReducer,
    state: AppState(
        user: UserState(isSignedIn: false, userID: nil, error: nil),
        registration: RegistrationState(isRegistered: false, deviceUUID: nil, error: nil),
        onboarding: OnboardingState(currentStep: .intro, userName: ""),
        router: RouterState(currentDestination: .splash),
        audio: AudioState(isRecording: false, audioData: [])
    )
)

// MARK: - Main App Structure

@main
struct mahdiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var router = AppRouterViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    // Instance of UserRegistrationManager
    private let userRegistrationManager = UserRegistrationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(onboardingViewModel)
                // Provide the ReSwift store to the environment
                .environment(\.store, mainStore)
                .onAppear {
                    Constants.initializeDefaults()
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let error = error {
                            print("Restore sign-in failed with error: \(error.localizedDescription)")
                            // Dispatch SignInFailureAction
                            mainStore.dispatch(SignInFailureAction(error: error.localizedDescription))
                            return
                        }
                        if let user = user {
                            print("Successfully restored previous sign-in for user ID: \(user.userID ?? "nil")")
                            // Dispatch SignInAction
                            if let userID = user.userID {
                                mainStore.dispatch(SignInAction(userID: userID))
                            }
                            // Use UserRegistrationManager to handle registration
                            userRegistrationManager.initiateRegistration(for: user)
                        } else {
                            print("No previous sign-in found.")
                        }
                    }
                }
        }
    }
}

// MARK: - AppDelegate for Google Sign-In URL handling

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication, open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - AppRouterViewModel for navigation management

class AppRouterViewModel: ObservableObject, StoreSubscriber {
    @Published var currentDestination: RouterDestination = .splash

    init() {
        mainStore.subscribe(self) { subscription in
            subscription.select { state in state.router }
        }
    }

    func newState(state: RouterState) {
        DispatchQueue.main.async {
            withAnimation {
                self.currentDestination = state.currentDestination
            }
        }
    }

    func navigate(to destination: RouterDestination) {
        mainStore.dispatch(NavigateAction(destination: destination))
    }

    func navigateToOnboarding() {
        mainStore.dispatch(NavigateAction(destination: .onboarding))
    }

    func navigateToHome() {
        mainStore.dispatch(NavigateAction(destination: .home))
    }
}

// MARK: - RouterDestination Enum

enum RouterDestination: Identifiable {
    case splash
    case onboarding
    case home

    var id: UUID {
        UUID()
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var router: AppRouterViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @Environment(\.store) var store: Store<AppState>

    var body: some View {
        ZStack {
            switch router.currentDestination {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingIntroView(
                    step: $onboardingViewModel.currentStep,
                    userName: $onboardingViewModel.userName
                )
                // Additional comments from original code
                .transition(.slide)
            case .home:
                MainContentView()
            }
        }
        .animation(.easeInOut, value: router.currentDestination)
        // Subscribe to the store for state changes if needed
        .onAppear {
            // Example: You can dispatch actions here if needed
        }
    }
}

// MARK: - Environment Key for ReSwift Store

struct ReSwiftStoreKey: EnvironmentKey {
    static let defaultValue: Store<AppState> = mainStore
}

extension EnvironmentValues {
    var store: Store<AppState> {
        get { self[ReSwiftStoreKey.self] }
        set { self[ReSwiftStoreKey.self] = newValue }
    }
}
