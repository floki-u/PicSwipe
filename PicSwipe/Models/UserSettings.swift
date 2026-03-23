import Foundation
import SwiftData

@Model
final class UserSettings {
    var batchSize: Int = 20
    var hasSeenTutorial: Bool = false

    init(batchSize: Int = 20, hasSeenTutorial: Bool = false) {
        self.batchSize = batchSize
        self.hasSeenTutorial = hasSeenTutorial
    }
}
