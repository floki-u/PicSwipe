import Foundation
import SwiftData
import Observation

/// 首页 ViewModel — 负责聚合存储信息、照片统计和用户设置
@Observable
final class HomeViewModel {

    // MARK: - 状态属性

    var storageInfo: StorageInfo = StorageInfo(totalSpace: 0, usedSpace: 0)
    var photoCount: Int = 0
    var videoCount: Int = 0
    var totalDeletedCount: Int = 0
    var totalFreedSpace: Int64 = 0
    var selectedMode: CleanMode = .photo
    var batchSize: Int = 20
    var isLoading: Bool = false

    // MARK: - 快捷筛选计数

    var screenshotCount: Int = 0
    var largeFileCount: Int = 0

    // MARK: - 数据加载

    @MainActor
    func loadData(
        photoService: PhotoLibraryService,
        storageService: StorageService,
        statsService: StatisticsService,
        modelContext: ModelContext
    ) async {
        isLoading = true
        storageInfo = storageService.fetchStorageInfo()
        photoCount = await photoService.fetchAssetCount(for: .image)
        videoCount = await photoService.fetchAssetCount(for: .video)
        totalDeletedCount = statsService.totalDeletedCount(in: modelContext)
        totalFreedSpace = statsService.totalFreedSpace(in: modelContext)
        batchSize = statsService.getSettings(in: modelContext).batchSize

        // 异步加载快捷筛选计数
        screenshotCount = await photoService.fetchScreenshotCount()
        largeFileCount = await photoService.fetchLargeFileCount()

        isLoading = false
    }
}
