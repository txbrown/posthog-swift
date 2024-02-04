import XCTest
@testable import PostHog

final class Tests: XCTestCase {
    #if os(macOS)
    func testDeviceIsMac() {
      XCTAssertEqual(Device.modelName, "Simulator macOS")
    }
    #endif
}
