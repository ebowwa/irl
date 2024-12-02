import ComposableArchitecture
@testable import mahdi
import XCTest

final class AppTests: XCTestCase {
    func testInitialState() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )

        // Add your tests here
    }
}
