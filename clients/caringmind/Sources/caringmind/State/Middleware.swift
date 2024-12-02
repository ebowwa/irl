import Foundation
import ReSwift

let loggerMiddleware: Middleware<AppState> = { dispatch, getState in
    return { next in
        return { action in
            print("⬇️ Dispatching action: \(action)")
            next(action)
            if let state = getState() {
                print("⬆️ New State: \(state)")
            }
        }
    }
}

let authMiddleware: Middleware<AppState> = { dispatch, getState in
    return { next in
        return { action in
            next(action)
            
            switch action {
            case let authAction as AuthAction:
                switch authAction {
                case .signIn(let user):
                    // Handle successful sign in
                    dispatch(NavigationAction.setLoading(false))
                    dispatch(NavigationAction.navigate(.home))
                    
                case .signOut:
                    // Handle sign out
                    dispatch(NavigationAction.navigate(.splash))
                    
                case .signInFailure(let error):
                    // Handle sign in error
                    print("Sign in error: \(error.localizedDescription)")
                    dispatch(NavigationAction.setLoading(false))
                    
                default:
                    break
                }
            default:
                break
            }
        }
    }
}

let audioMiddleware: Middleware<AppState> = { dispatch, getState in
    return { next in
        return { action in
            next(action)
            
            switch action {
            case let audioAction as AudioAction:
                switch audioAction {
                case .startRecording:
                    // Handle start recording
                    break
                    
                case .stopRecording:
                    // Handle stop recording
                    break
                    
                case .recordingError(let error):
                    // Handle recording error
                    print("Recording error: \(error.localizedDescription)")
                    break
                    
                default:
                    break
                }
            default:
                break
            }
        }
    }
}

let navigationMiddleware: Middleware<AppState> = { dispatch, getState in
    return { next in
        return { action in
            next(action)
            
            switch action {
            case let navAction as NavigationAction:
                switch navAction {
                case .navigate(let route):
                    print("Navigating to: \(route)")
                    // Add any navigation side effects here
                    break
                    
                case .setLoading(let isLoading):
                    print("Setting loading state: \(isLoading)")
                    break
                    
                default:
                    break
                }
            default:
                break
            }
        }
    }
}
