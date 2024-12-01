import XCTest
import ComposableArchitecture
@testable import mahdi

final class AppTests: XCTestCase {
    func testInitialState() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        // Add your tests here
    }
}
