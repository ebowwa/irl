import SwiftUI
import ReSwift

// MARK: - Store Subscriber Property Wrapper
@propertyWrapper
struct StoreState<T> {
    @StateObject private var subscriber = Subscriber<T>()
    let keyPath: KeyPath<AppState, T>
    
    init(_ keyPath: KeyPath<AppState, T>) {
        self.keyPath = keyPath
    }
    
    var wrappedValue: T {
        subscriber.value ?? Store.shared.getState()[keyPath: keyPath]
    }
    
    var projectedValue: Binding<T> {
        Binding(
            get: { wrappedValue },
            set: { newValue in
                subscriber.value = newValue
            }
        )
    }
}

// MARK: - Subscriber Implementation
class Subscriber<T>: ObservableObject {
    @Published var value: T?
}

// MARK: - View Extension
extension View {
    func withStoreSubscription<T>(_ keyPath: KeyPath<AppState, T>) -> some View {
        let subscriber = Subscriber<T>()
        return self
            .onAppear {
                Store.shared.subscribe { subscription in
                    subscriber.value = subscription.state[keyPath: keyPath]
                }
            }
            .onDisappear {
                Store.shared.unsubscribe(subscriber)
            }
    }
}
