import Foundation

/// 筛选条件 — 用于过滤照片/视频资源
struct FilterCriteria: Hashable {
    // MARK: - 时间范围
    var startDate: Date?
    var endDate: Date?

    // MARK: - 相册
    var albumIdentifiers: [String]?

    // MARK: - 快捷筛选
    /// 仅截图
    var screenshotsOnly: Bool = false
    /// 大文件优先（fileSize > largeFileThreshold）
    var largeFilesOnly: Bool = false
    /// 大文件阈值，默认 10MB
    var largeFileThreshold: Int64 = 10_485_760
    /// 按文件大小降序排列（而非随机）
    var sortBySize: Bool = false

    // MARK: - 辅助

    /// 是否有任何筛选条件被激活
    var hasActiveFilter: Bool {
        startDate != nil || endDate != nil ||
        (albumIdentifiers != nil && !(albumIdentifiers!.isEmpty)) ||
        screenshotsOnly || largeFilesOnly
    }
}
