import XCTest
@testable import PicSwipe

final class StorageServiceTests: XCTestCase {
    func test_fetchStorageInfo_returnsTotalGreaterThanZero() {
        let service = StorageService()
        let info = service.fetchStorageInfo()
        XCTAssertGreaterThan(info.totalSpace, 0)
        XCTAssertGreaterThan(info.usedSpace, 0)
    }

    func test_usagePercentage_calculatesCorrectly() {
        let info = StorageInfo(totalSpace: 100, usedSpace: 72)
        XCTAssertEqual(info.usagePercentage, 0.72, accuracy: 0.01)
    }

    func test_storageLevel_normal() {
        let info = StorageInfo(totalSpace: 100, usedSpace: 50)
        XCTAssertEqual(info.level, .normal)
    }

    func test_storageLevel_warning() {
        let info = StorageInfo(totalSpace: 100, usedSpace: 80)
        XCTAssertEqual(info.level, .warning)
    }

    func test_storageLevel_critical() {
        let info = StorageInfo(totalSpace: 100, usedSpace: 95)
        XCTAssertEqual(info.level, .critical)
    }
}
