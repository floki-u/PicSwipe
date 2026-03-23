import XCTest

final class PicSwipeUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func test_appLaunches_showsPicSwipeText() {
        let exists = app.staticTexts["PicSwipe"].waitForExistence(timeout: 5)
        XCTAssertTrue(exists)
    }
}
