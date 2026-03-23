import Foundation
import SwiftData
import Observation

@Observable
final class StatisticsService {

    // MARK: - 统计查询

    func totalDeletedCount(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CleanRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.deletedCount }
    }

    func totalFreedSpace(in context: ModelContext) -> Int64 {
        let descriptor = FetchDescriptor<CleanRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.freedSpace }
    }

    // MARK: - 记录清理

    func recordClean(deletedCount: Int, freedSpace: Int64, mode: CleanMode, in context: ModelContext) {
        let record = CleanRecord(deletedCount: deletedCount, freedSpace: freedSpace, mode: mode)
        context.insert(record)
        try? context.save()
    }

    // MARK: - 用户设置

    func getSettings(in context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? context.fetch(descriptor).first { return existing }
        let settings = UserSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
