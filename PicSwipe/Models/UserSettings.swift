import Foundation
import SwiftData

@Model
final class UserSettings {
    var batchSize: Int = 20
    var hasSeenTutorial: Bool = false
    /// 用户是否已经执行过至少一次删除操作（用于跳过首次后的系统确认提示说明）
    var hasConfirmedDeleteBefore: Bool = false

    init(batchSize: Int = 20, hasSeenTutorial: Bool = false, hasConfirmedDeleteBefore: Bool = false) {
        self.batchSize = batchSize
        self.hasSeenTutorial = hasSeenTutorial
        self.hasConfirmedDeleteBefore = hasConfirmedDeleteBefore
    }
}
