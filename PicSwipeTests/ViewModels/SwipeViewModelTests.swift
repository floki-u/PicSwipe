// PicSwipeTests/ViewModels/SwipeViewModelTests.swift
import XCTest
import Photos
@testable import PicSwipe

final class SwipeViewModelTests: XCTestCase {

    // MARK: - 辅助方法

    private func makeSession(assetCount: Int = 3, mode: CleanMode = .photo) -> CleanSession {
        let mediaType: PHAssetMediaType = mode == .photo ? .image : .video
        let assets = (0..<assetCount).map {
            AssetItem(
                localIdentifier: "asset-\($0)",
                fileSize: Int64($0 + 1) * 1024,
                creationDate: Date(),
                mediaType: mediaType
            )
        }
        return CleanSession(mode: mode, assets: assets)
    }

    // MARK: - 测试用例

    func test_keepCurrent_advancesToNextAndDoesNotMark() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3)

        vm.keepCurrent()

        XCTAssertEqual(vm.session?.currentIndex, 1)
        XCTAssertFalse(vm.session!.assets[0].markedForDeletion)
        XCTAssertFalse(vm.isFinished)
    }

    func test_deleteCurrent_marksAndAdvances() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3)

        vm.deleteCurrent()

        XCTAssertEqual(vm.session?.currentIndex, 1)
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion)
        XCTAssertFalse(vm.isFinished)
    }

    func test_goBack_fromIndexZero_doesNothing() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3)

        vm.goBack()

        XCTAssertEqual(vm.session?.currentIndex, 0)
    }

    func test_goBack_fromIndexOne_goesBack() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3)

        vm.keepCurrent()  // 推进到 index 1
        XCTAssertEqual(vm.session?.currentIndex, 1)

        vm.goBack()
        XCTAssertEqual(vm.session?.currentIndex, 0)
    }

    func test_deleteCurrent_atLastAsset_setsIsFinished() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 2)

        vm.keepCurrent()   // index 0 → 1（最后一个）
        XCTAssertFalse(vm.isFinished)

        vm.deleteCurrent() // 在最后一个资源上标记删除
        XCTAssertTrue(vm.isFinished)
        XCTAssertTrue(vm.session!.assets[1].markedForDeletion)
    }

    func test_goBack_thenRedelete_overridesMark() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3)

        // 先保留第一个
        vm.keepCurrent()
        XCTAssertFalse(vm.session!.assets[0].markedForDeletion)

        // 回看
        vm.goBack()
        XCTAssertEqual(vm.session?.currentIndex, 0)

        // 改为删除
        vm.deleteCurrent()
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion)
        XCTAssertEqual(vm.session?.currentIndex, 1)
    }

    func test_markedCount_tracksCorrectly() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 4)

        XCTAssertEqual(vm.markedCount, 0)

        vm.deleteCurrent()  // 删除 asset-0
        XCTAssertEqual(vm.markedCount, 1)

        vm.keepCurrent()    // 保留 asset-1
        XCTAssertEqual(vm.markedCount, 1)

        vm.deleteCurrent()  // 删除 asset-2
        XCTAssertEqual(vm.markedCount, 2)

        // 回看到 asset-2，改为保留
        vm.goBack()
        vm.keepCurrent()
        XCTAssertEqual(vm.markedCount, 1)
    }

    // MARK: - 视频模式操作

    func test_advanceToNext_movesToNextWithoutMarking() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3, mode: .video)

        vm.advanceToNext()

        XCTAssertEqual(vm.session?.currentIndex, 1)
        XCTAssertFalse(vm.session!.assets[0].markedForDeletion)
        XCTAssertFalse(vm.isFinished)
    }

    func test_advanceToNext_atLastAsset_setsIsFinished() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 2, mode: .video)

        vm.advanceToNext()  // index 0 → 1（最后一个）
        XCTAssertFalse(vm.isFinished)

        vm.advanceToNext()  // 在最后一个上再次调用
        XCTAssertTrue(vm.isFinished)
        XCTAssertEqual(vm.session?.currentIndex, 1)
    }

    func test_advanceToNext_withNilSession_doesNothing() {
        let vm = SwipeViewModel()

        vm.advanceToNext()

        XCTAssertNil(vm.session)
        XCTAssertFalse(vm.isFinished)
    }

    func test_markDeleteAndAdvance_marksCurrentAndAdvances() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3, mode: .video)

        vm.markDeleteAndAdvance()

        XCTAssertEqual(vm.session?.currentIndex, 1)
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion)
        XCTAssertFalse(vm.isFinished)
        XCTAssertEqual(vm.markedCount, 1)
    }

    func test_markDeleteAndAdvance_atLastAsset_setsIsFinished() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 2, mode: .video)

        vm.advanceToNext()  // index 0 → 1（最后一个）
        vm.markDeleteAndAdvance()

        XCTAssertTrue(vm.isFinished)
        XCTAssertTrue(vm.session!.assets[1].markedForDeletion)
        XCTAssertEqual(vm.session?.currentIndex, 1)
    }

    func test_undoLastMark_unmarksLastMarkedItem() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3, mode: .video)

        vm.markDeleteAndAdvance()
        XCTAssertEqual(vm.markedCount, 1)

        let indexBeforeUndo = vm.session?.currentIndex
        vm.undoLastMark()

        XCTAssertEqual(vm.markedCount, 0)
        XCTAssertFalse(vm.session!.assets[0].markedForDeletion)
        XCTAssertEqual(vm.session?.currentIndex, indexBeforeUndo, "undoLastMark 不应改变 currentIndex")
    }

    func test_undoLastMark_withNoMarkedItems_doesNothing() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 3, mode: .video)
        let originalIndex = vm.session?.currentIndex

        vm.undoLastMark()

        XCTAssertEqual(vm.markedCount, 0)
        XCTAssertEqual(vm.session?.currentIndex, originalIndex, "undoLastMark 不应改变 currentIndex")
    }

    func test_undoLastMark_withMultipleMarked_onlyUnmarksLast() {
        let vm = SwipeViewModel()
        vm.session = makeSession(assetCount: 4, mode: .video)

        vm.markDeleteAndAdvance()
        vm.advanceToNext()
        vm.markDeleteAndAdvance()
        XCTAssertEqual(vm.markedCount, 2)

        let indexBeforeUndo = vm.session?.currentIndex
        vm.undoLastMark()

        XCTAssertEqual(vm.markedCount, 1)
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion, "asset-0 仍然标记")
        XCTAssertFalse(vm.session!.assets[2].markedForDeletion, "asset-2 被撤回")
        XCTAssertEqual(vm.session?.currentIndex, indexBeforeUndo, "undoLastMark 不应改变 currentIndex")
    }
}
