// PicSwipe/ViewModels/SwipeViewModel.swift
import SwiftUI
import Observation

/// 滑动方向
enum SwipeDirection {
    case up, left, down, right, none
}

/// 滑动浏览页视图模型
/// 管理滑动手势状态、当前索引推进、标记删除逻辑
@Observable
final class SwipeViewModel {

    // MARK: - 会话状态

    var session: CleanSession?
    var isFinished: Bool = false
    var showUI: Bool = true  // 纯净模式开关

    // MARK: - 手势状态

    var dragOffset: CGSize = .zero
    var dragDirection: SwipeDirection = .none

    // MARK: - 计算属性

    /// 当前标记删除的数量
    var markedCount: Int {
        session?.markedForDeletionCount ?? 0
    }

    /// 当前资源
    var currentAsset: AssetItem? {
        session?.currentAsset
    }

    /// 当前索引
    var currentIndex: Int {
        session?.currentIndex ?? 0
    }

    /// 资源总数
    var totalCount: Int {
        session?.assets.count ?? 0
    }

    // MARK: - 操作

    /// 上滑保留：不标记当前资源，推进到下一个
    func keepCurrent() {
        guard var s = session else { return }
        guard s.currentIndex < s.assets.count else { return }
        s.assets[s.currentIndex].markedForDeletion = false
        if s.isAtLastAsset {
            s.currentIndex = s.assets.count - 1
            session = s
            isFinished = true
        } else {
            s.currentIndex += 1
            session = s
        }
        resetDrag()
    }

    /// 左滑删除：标记当前资源为删除，推进到下一个
    func deleteCurrent() {
        guard var s = session else { return }
        guard s.currentIndex < s.assets.count else { return }
        s.assets[s.currentIndex].markedForDeletion = true
        if s.isAtLastAsset {
            s.currentIndex = s.assets.count - 1
            session = s
            isFinished = true
        } else {
            s.currentIndex += 1
            session = s
        }
        resetDrag()
    }

    /// 下滑回看：回到上一个资源
    func goBack() {
        guard var s = session else { return }
        guard s.currentIndex > 0 else { return }
        s.currentIndex -= 1
        session = s
        isFinished = false
        resetDrag()
    }

    /// 切换纯净模式
    func toggleUI() {
        showUI.toggle()
    }

    // MARK: - 手势辅助

    /// 根据拖拽位移判断主方向
    func detectDirection(translation: CGSize) -> SwipeDirection {
        let absX = abs(translation.width)
        let absY = abs(translation.height)

        // 需要有一定位移才判断方向
        guard absX > 10 || absY > 10 else { return .none }

        if absY > absX {
            // 纵向为主
            return translation.height < 0 ? .up : .down
        } else {
            // 横向为主
            return translation.width < 0 ? .left : .right
        }
    }

    /// 判断位移是否超过阈值（屏幕尺寸的 1/3）
    func isOverThreshold(translation: CGSize, screenSize: CGSize) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        let thresholdX = screenSize.width / 3
        let thresholdY = screenSize.height / 3
        return absX > thresholdX || absY > thresholdY
    }

    /// 计算卡片旋转角度，最大 ±10°，基于水平位移
    func rotationAngle(translation: CGSize, screenWidth: CGFloat) -> Angle {
        guard screenWidth > 0 else { return .zero }
        let maxAngle: Double = 10
        let ratio = Double(translation.width) / Double(screenWidth)
        let clamped = max(-1, min(1, ratio))
        return .degrees(clamped * maxAngle)
    }

    // MARK: - 私有方法

    private func resetDrag() {
        dragOffset = .zero
        dragDirection = .none
    }
}
