import XCTest
@testable import PostHog

final class Tests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(posthog_swift().text, "Hello, World!")
    }


}
