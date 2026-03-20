import UIKit

// MARK: - HapticService

/// 触觉反馈服务 — 集中管理所有触觉反馈
enum HapticService {
    /// 拖拽方向越过阈值时触发
    static func thresholdReached(direction: SwipeDirection) {
        switch direction {
        case .up:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .left:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        default: break
        }
    }

    /// 手势确认（onEnded 触发动作）时触发
    static func gestureTriggered() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// 删除成功时触发
    static func deleteSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 删除失败时触发
    static func deleteError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// 到达边界（如 index 0 无法回退）时触发
    static func boundaryReached() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
