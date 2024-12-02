import Foundation
import ReSwift

// MARK: - Store Container
final class StoreContainer {
    static let shared = StoreContainer()
    
    let store: Store<AppState>
    
    private init() {
        store = Store<AppState>(
            reducer: appReducer,
            state: AppState.initialState,
            middleware: [
                loggerMiddleware,
                authMiddleware,
                audioMiddleware,
                navigationMiddleware
            ]
        )
    }
}

// MARK: - Store Access
extension Store {
    static var shared: Store<AppState> {
        return StoreContainer.shared.store
    }
    
    func dispatchOnMain(_ action: Action) {
        DispatchQueue.main.async {
            self.dispatch(action)
        }
    }
}
