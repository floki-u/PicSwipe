import XCTest
@testable import PicSwipe

final class PhotoLibraryServiceTests: XCTestCase {
    func test_getFileSize_withNilAsset_returnsZero() {
        let size = PhotoLibraryService.getFileSize(for: nil)
        XCTAssertEqual(size, 0)
    }
}
