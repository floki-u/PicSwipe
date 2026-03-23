import XCTest
@testable import PicSwipe

final class CleanSessionTests: XCTestCase {
    func test_init_startsAtIndexZero() {
        let session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200)
            ]
        )
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertEqual(session.assets.count, 2)
        XCTAssertEqual(session.mode, .photo)
    }

    func test_markedForDeletionCount_returnsCorrectCount() {
        var session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200),
                AssetItem(localIdentifier: "c", fileSize: 300)
            ]
        )
        session.assets[0].markedForDeletion = true
        session.assets[2].markedForDeletion = true
        XCTAssertEqual(session.markedForDeletionCount, 2)
        XCTAssertEqual(session.markedForDeletionTotalSize, 400)
    }

    func test_isLastAsset_correctAtBoundary() {
        let session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200)
            ]
        )
        XCTAssertFalse(session.isAtLastAsset)
    }

    func test_currentAsset_returnsCorrectAsset() {
        let session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200)
            ]
        )
        XCTAssertEqual(session.currentAsset?.localIdentifier, "a")
    }

    func test_markedAssets_returnsOnlyMarked() {
        var session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200),
                AssetItem(localIdentifier: "c", fileSize: 300)
            ]
        )
        session.assets[1].markedForDeletion = true
        XCTAssertEqual(session.markedAssets.count, 1)
        XCTAssertEqual(session.markedAssets[0].localIdentifier, "b")
    }
}
