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

    // MARK: - 数据加载

    /// 从各 Service 聚合首页所需数据
    /// - Parameters:
    ///   - photoService: 相册服务
    ///   - storageService: 存储服务
    ///   - statsService: 统计服务
    ///   - modelContext: SwiftData 上下文
    func loadData(
        photoService: PhotoLibraryService,
        storageService: StorageService,
        statsService: StatisticsService,
        modelContext: ModelContext
    ) {
        isLoading = true
        storageInfo = storageService.fetchStorageInfo()
        photoCount = photoService.fetchAssetCount(for: .image)
        videoCount = photoService.fetchAssetCount(for: .video)
        totalDeletedCount = statsService.totalDeletedCount(in: modelContext)
        totalFreedSpace = statsService.totalFreedSpace(in: modelContext)
        batchSize = statsService.getSettings(in: modelContext).batchSize
        isLoading = false
    }
}
