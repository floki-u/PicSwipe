import Foundation

/// 一次清理会话（内存模型，不持久化）
struct CleanSession {
    let id: UUID = UUID()
    let mode: CleanMode
    let filter: FilterCriteria?
    var assets: [AssetItem]
    var currentIndex: Int = 0

    init(mode: CleanMode, assets: [AssetItem], filter: FilterCriteria? = nil) {
        self.mode = mode
        self.assets = assets
        self.filter = filter
    }

    var markedForDeletionCount: Int {
        assets.filter(\.markedForDeletion).count
    }

    var markedForDeletionTotalSize: Int64 {
        assets.filter(\.markedForDeletion).reduce(0) { $0 + $1.fileSize }
    }

    var markedAssets: [AssetItem] {
        assets.filter(\.markedForDeletion)
    }

    var isAtLastAsset: Bool {
        currentIndex >= assets.count - 1
    }

    var currentAsset: AssetItem? {
        guard currentIndex >= 0, currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }
}
