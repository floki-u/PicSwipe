import XCTest
import SwiftData
@testable import PicSwipe

final class StatisticsServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var service: StatisticsService!

    override func setUp() {
        super.setUp()
        let schema = Schema([CleanRecord.self, UserSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        service = StatisticsService()
    }

    func test_totalDeletedCount_withNoRecords_returnsZero() {
        XCTAssertEqual(service.totalDeletedCount(in: context), 0)
    }

    func test_totalDeletedCount_sumsAllRecords() {
        context.insert(CleanRecord(deletedCount: 5, freedSpace: 1000, mode: .photo))
        context.insert(CleanRecord(deletedCount: 3, freedSpace: 2000, mode: .photo))
        try? context.save()
        XCTAssertEqual(service.totalDeletedCount(in: context), 8)
    }

    func test_totalFreedSpace_sumsAllRecords() {
        context.insert(CleanRecord(deletedCount: 5, freedSpace: 1000, mode: .photo))
        context.insert(CleanRecord(deletedCount: 3, freedSpace: 2000, mode: .photo))
        try? context.save()
        XCTAssertEqual(service.totalFreedSpace(in: context), 3000)
    }

    func test_getSettings_createsDefaultIfNotExists() {
        let settings = service.getSettings(in: context)
        XCTAssertEqual(settings.batchSize, 20)
        XCTAssertFalse(settings.hasSeenTutorial)
    }
}
