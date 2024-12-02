//
//  CaringMindApp.swift
//  CaringMind
//
//  General App Description: this product is meant to listen 24/7 it uses the openaudio which allows for processing of audio from devices and storing, post requests, websocket, audio playing controls, local audio measurement, etc
// - this app should always be recording, it may be recording for local storage, for batch uploads to server, or for a live-streaming websocket
// - this functionality should not be managed by views, but can be modified, i.e., switch to websocket, send data to server, playbacks, viewing transcriptions, data, etc
//
// NOTE: this script was updated to include a google sign in which as of now does nothing, it works, the user can sign in with their google account but otherwise this feature has no other extension, moving forward location, usage metrics, drive storage can be applied through this gsignin

import SwiftUI
import GoogleSignIn
#if os(iOS)
import UIKit
#endif
import ReSwift
import ComposableArchitecture

// MARK: - App State Management

// Define the AppState which holds the entire state of the application
struct AppState: Equatable {
    // User State
    var isSignedIn: Bool = false
    var userID: String?
    var userError: String?

    // Registration State
    var isRegistered: Bool = false
    var deviceUUID: String?
    var registrationError: String?

    // Onboarding State
    var onboardingStep: OnboardingStep = .intro
    var userName: String = ""

    // Router State
    var currentDestination: RouterDestination = .splash

    // Audio State
    var isRecording: Bool = false
    var audioData: [AudioData] = []

    // Navigation State
    var navigation: NavigationState = NavigationState()

    static var initialState: AppState {
        return AppState()
    }
}

// Define Onboarding Steps
enum OnboardingStep {
    case intro
    case permissions
    case completion
}

// MARK: - AudioData Structure

struct AudioData: Codable {
    var data: Data
    var timestamp: Date
}

// MARK: - Navigation State

struct NavigationState: Equatable {
    var currentRoute: Route = .splash
    var isLoading: Bool = false
}

enum Route: Equatable {
    case splash
    case home
    case onboarding
    case nameInput
    case settings
}

// MARK: - Store

class Store {
    static let shared = Store()

    let store = Store<AppState, Action>(reducer: appReducer, state: AppState.initialState())

    func dispatch(_ action: Action) {
        store.dispatch(action)
    }

    func dispatchOnMain(_ action: Action) {
        DispatchQueue.main.async {
            self.dispatch(action)
        }
    }

    func subscribe(_ subscriber: StoreSubscriber) {
        store.subscribe(subscriber)
    }

    func unsubscribe(_ subscriber: StoreSubscriber) {
        store.unsubscribe(subscriber)
    }
}

// MARK: - Actions

enum Action: Equatable {
    case auth(AuthAction)
    case navigation(NavigationAction)
}

enum AuthAction: Equatable {
    case signIn(GIDGoogleUser)
    case signInFailure(Error)
}

enum NavigationAction: Equatable {
    case navigateTo(Route)
    case setLoading(Bool)
}

// MARK: - Reducer

func appReducer(_ state: inout AppState, _ action: Action) -> [Effect<Action>] {
    switch action {
    case .auth(let authAction):
        switch authAction {
        case .signIn(let user):
            state.isSignedIn = true
            state.userID = user.userID
            state.userError = nil
            return [Effect(value: .navigation(.navigateTo(.home)))]
        case .signInFailure(let error):
            state.userError = error.localizedDescription
            state.isSignedIn = false
            return []
        }
    case .navigation(let navigationAction):
        switch navigationAction {
        case .navigateTo(let route):
            state.navigation.currentRoute = route
            return []
        case .setLoading(let isLoading):
            state.navigation.isLoading = isLoading
            return []
        }
    }

    return []
}

// MARK: - App State Observable
class AppStateObservable: ObservableObject {
    @Published var state: AppState
    private let store: Store<AppState>
    
    init() {
        state = AppState.initialState
        store = Store<AppState>(
            reducer: appReducer,
            state: state,
            middleware: [
                loggerMiddleware,
                authMiddleware,
                audioMiddleware,
                navigationMiddleware
            ]
        )
        
        store.subscribe { [weak self] subscription in
            self?.state = subscription.state
        }
    }
    
    func dispatch(_ action: Action) {
        store.dispatch(action)
    }
}

// MARK: - Main App Structure

@main
struct CaringMindApp: App {
    @StateObject private var appStateObservable = AppStateObservable()
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStateObservable)
                .onAppear {
                    checkExistingSignIn()
                }
        }
    }
    
    private func checkExistingSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                Store.shared.dispatchOnMain(.auth(.signInFailure(error)))
                return
            }
            
            if let user = user {
                Store.shared.dispatchOnMain(.auth(.signIn(user)))
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Google Sign In
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring sign in: \(error.localizedDescription)")
                return
            }
            
            if let user = user {
                Store.shared.dispatch(.auth(.signIn(user)))
            }
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

struct ContentView: View {
    @EnvironmentObject var appStateObservable: AppStateObservable
    
    var body: some View {
        Group {
            switch appStateObservable.state.navigation.currentRoute {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .home:
                HomeView()
            case .settings:
                SettingsView()
            }
        }
    }
}
