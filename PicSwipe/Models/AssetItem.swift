import Photos

/// 当前浏览会话中的一个资源（内存模型，不持久化）
struct AssetItem: Identifiable {
    let id: String
    let phAsset: PHAsset?
    let localIdentifier: String
    var markedForDeletion: Bool = false
    var fileSize: Int64
    var creationDate: Date?
    var mediaType: PHAssetMediaType

    /// 便捷初始化器（用于测试）
    init(localIdentifier: String, fileSize: Int64, creationDate: Date? = nil, mediaType: PHAssetMediaType = .image) {
        self.id = localIdentifier
        self.phAsset = nil
        self.localIdentifier = localIdentifier
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.mediaType = mediaType
    }

    /// 从 PHAsset 构建
    init(phAsset: PHAsset, fileSize: Int64) {
        self.id = phAsset.localIdentifier
        self.phAsset = phAsset
        self.localIdentifier = phAsset.localIdentifier
        self.fileSize = fileSize
        self.creationDate = phAsset.creationDate
        self.mediaType = phAsset.mediaType
    }
}
