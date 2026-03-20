// PicSwipeTests/ViewModels/ConfirmDeleteViewModelTests.swift
import XCTest
@testable import PicSwipe

final class ConfirmDeleteViewModelTests: XCTestCase {

    func test_loadFromSession_populatesMarkedAssets() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
            AssetItem(localIdentifier: "c", fileSize: 300),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[2].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)
        XCTAssertEqual(vm.markedAssets.count, 2)
        XCTAssertEqual(vm.totalSize, 400)
    }

    func test_revokeMarking_removesAsset() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[1].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)
        vm.revokeMarking(for: "a")
        XCTAssertEqual(vm.markedAssets.count, 1)
        XCTAssertEqual(vm.markedAssets[0].localIdentifier, "b")
    }

    func test_revokeAll_clearsAllMarks() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[1].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)
        vm.revokeAll()
        XCTAssertEqual(vm.markedAssets.count, 0)
    }

    func test_revokeMarking_adjustsPreviewIndexWhenAtEnd() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[1].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)
        vm.currentPreviewIndex = 1
        vm.revokeMarking(for: "b")
        XCTAssertEqual(vm.currentPreviewIndex, 0)
    }

    func test_totalSize_returnsZeroWhenEmpty() {
        let vm = ConfirmDeleteViewModel()
        XCTAssertEqual(vm.totalSize, 0)
    }
}
