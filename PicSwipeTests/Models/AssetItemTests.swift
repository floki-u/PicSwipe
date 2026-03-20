import XCTest
@testable import PicSwipe

final class AssetItemTests: XCTestCase {
    func test_init_defaultMarkedForDeletionIsFalse() {
        let item = AssetItem(localIdentifier: "test-id", fileSize: 1024)
        XCTAssertFalse(item.markedForDeletion)
        XCTAssertEqual(item.localIdentifier, "test-id")
        XCTAssertEqual(item.fileSize, 1024)
    }

    func test_toggleDeletion_flipsFlag() {
        var item = AssetItem(localIdentifier: "test-id", fileSize: 1024)
        item.markedForDeletion = true
        XCTAssertTrue(item.markedForDeletion)
        item.markedForDeletion = false
        XCTAssertFalse(item.markedForDeletion)
    }
}
