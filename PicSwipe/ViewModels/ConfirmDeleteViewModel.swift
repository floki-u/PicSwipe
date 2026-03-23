// PicSwipe/ViewModels/ConfirmDeleteViewModel.swift
import SwiftUI
import Observation

/// 确认删除页视图模型
/// 管理待删除资源列表、预览索引、撤回操作
@Observable
final class ConfirmDeleteViewModel {
    var markedAssets: [AssetItem] = []
    var currentPreviewIndex: Int = 0
    var isDeleting: Bool = false

    // MARK: - 初始化

    /// 从清理会话加载已标记资源
    func loadFromSession(_ session: CleanSession?) {
        guard let session = session else { return }
        markedAssets = session.markedAssets
        currentPreviewIndex = 0
    }

    // MARK: - 计算属性

    /// 所有待删除资源的总文件大小
    var totalSize: Int64 {
        markedAssets.reduce(0) { $0 + $1.fileSize }
    }

    // MARK: - 操作

    /// 撤回单张照片的删除标记
    /// - Parameter identifier: 资源的 localIdentifier
    func revokeMarking(for identifier: String) {
        markedAssets.removeAll { $0.localIdentifier == identifier }
        if currentPreviewIndex >= markedAssets.count {
            currentPreviewIndex = max(0, markedAssets.count - 1)
        }
    }

    /// 撤回全部删除标记
    func revokeAll() {
        markedAssets.removeAll()
        currentPreviewIndex = 0
    }
}
