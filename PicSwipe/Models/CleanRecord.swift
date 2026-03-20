import Foundation
import SwiftData

@Model
final class CleanRecord {
    var date: Date
    var deletedCount: Int
    var freedSpace: Int64
    var mode: String

    init(date: Date = .now, deletedCount: Int, freedSpace: Int64, mode: CleanMode) {
        self.date = date
        self.deletedCount = deletedCount
        self.freedSpace = freedSpace
        self.mode = mode.rawValue
    }

    var cleanMode: CleanMode {
        CleanMode(rawValue: mode) ?? .photo
    }
}
