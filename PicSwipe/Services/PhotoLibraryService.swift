import Photos
import PhotosUI
import UIKit
import Observation

/// 相册信息
struct AlbumInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let count: Int
}

/// 图片加载错误类型
enum ImageLoadError {
    case iCloudDownloadFailed
    case timeout
    case unknown
}

@Observable
final class PhotoLibraryService {

    // MARK: - 权限状态

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    var isAuthorized: Bool { authorizationStatus == .authorized }
    var isLimited: Bool { authorizationStatus == .limited }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - 照片读取

    func fetchAssetCount(for mediaType: PHAssetMediaType) async -> Int {
        await Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            return PHAsset.fetchAssets(with: options).count
        }.value
    }

    /// 获取截图数量
    func fetchScreenshotCount() async -> Int {
        await Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue),
                NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            ])
            return PHAsset.fetchAssets(with: options).count
        }.value
    }

    /// 获取大文件数量（使用采样估算，避免遍历全部资源）
    /// 策略：视频全部检查（通常数量少），照片按创建时间倒序采样前 500 张
    func fetchLargeFileCount(threshold: Int64 = 10_485_760) async -> Int {
        await Task.detached(priority: .userInitiated) {
            var count = 0

            // 视频通常体积大且数量少，全部检查
            let videoOptions = PHFetchOptions()
            videoOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let videoResult = PHAsset.fetchAssets(with: videoOptions)
            videoResult.enumerateObjects { asset, _, _ in
                if Self.getFileSize(for: asset) > threshold {
                    count += 1
                }
            }

            // 照片按时间倒序，采样前 500 张（最近的照片分辨率更高、体积更大）
            let photoOptions = PHFetchOptions()
            photoOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            photoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            photoOptions.fetchLimit = 500
            let photoResult = PHAsset.fetchAssets(with: photoOptions)
            photoResult.enumerateObjects { asset, _, _ in
                if Self.getFileSize(for: asset) > threshold {
                    count += 1
                }
            }

            return count
        }.value
    }

    /// 获取相册列表
    func fetchAlbums(for mediaType: PHAssetMediaType) async -> [AlbumInfo] {
        await Task.detached(priority: .userInitiated) {
            var albums: [AlbumInfo] = []

            // 智能相册（相机胶卷、截屏、最近项目等）
            let smartAlbums = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: .any, options: nil
            )
            smartAlbums.enumerateObjects { collection, _, _ in
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
                let assetCount = PHAsset.fetchAssets(in: collection, options: fetchOptions).count
                if assetCount > 0, let title = collection.localizedTitle {
                    albums.append(AlbumInfo(
                        id: collection.localIdentifier,
                        title: title,
                        count: assetCount
                    ))
                }
            }

            // 用户相册
            let userAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: nil
            )
            userAlbums.enumerateObjects { collection, _, _ in
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
                let assetCount = PHAsset.fetchAssets(in: collection, options: fetchOptions).count
                if assetCount > 0, let title = collection.localizedTitle {
                    albums.append(AlbumInfo(
                        id: collection.localIdentifier,
                        title: title,
                        count: assetCount
                    ))
                }
            }

            // 按数量降序排列
            return albums.sorted { $0.count > $1.count }
        }.value
    }

    /// 获取符合筛选条件的资源数量（用于筛选页实时计数）
    func fetchFilteredAssetCount(mode: CleanMode, filter: FilterCriteria) async -> Int {
        await Task.detached(priority: .userInitiated) {
            let assets = Self.fetchFilteredPHAssets(mode: mode, filter: filter)
            if filter.largeFilesOnly {
                return assets.filter { Self.getFileSize(for: $0) > filter.largeFileThreshold }.count
            }
            return assets.count
        }.value
    }

    func fetchRandomAssets(mode: CleanMode, count: Int, filter: FilterCriteria? = nil) async -> CleanSession {
        let session = await Task.detached(priority: .userInitiated) {
            var allAssets: [PHAsset]
            if let filter = filter, filter.hasActiveFilter {
                allAssets = Self.fetchFilteredPHAssets(mode: mode, filter: filter)

                // 大文件过滤
                if filter.largeFilesOnly {
                    allAssets = allAssets.filter { Self.getFileSize(for: $0) > filter.largeFileThreshold }
                }

                // 排序：大文件模式按大小降序，否则随机
                if filter.sortBySize || filter.largeFilesOnly {
                    allAssets.sort { Self.getFileSize(for: $0) > Self.getFileSize(for: $1) }
                    let selected = Array(allAssets.prefix(count))
                    let assetItems = selected.map { AssetItem(phAsset: $0, fileSize: Self.getFileSize(for: $0)) }
                    return CleanSession(mode: mode, assets: assetItems, filter: filter)
                }
            } else {
                let mediaType: PHAssetMediaType = mode == .photo ? .image : .video
                let options = PHFetchOptions()
                options.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
                let fetchResult = PHAsset.fetchAssets(with: options)
                allAssets = []
                fetchResult.enumerateObjects { asset, _, _ in allAssets.append(asset) }
            }

            // Fisher-Yates shuffle
            var shuffled = allAssets
            for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
                let j = Int.random(in: 0...i)
                shuffled.swapAt(i, j)
            }
            let selected = Array(shuffled.prefix(count))
            let assetItems = selected.map { AssetItem(phAsset: $0, fileSize: Self.getFileSize(for: $0)) }
            return CleanSession(mode: mode, assets: assetItems, filter: filter)
        }.value
        return session
    }

    func deleteAssets(_ assets: [AssetItem]) async throws -> Int {
        let phAssets = assets.compactMap(\.phAsset)
        guard !phAssets.isEmpty else { return 0 }
        let identifiers = phAssets.map(\.localIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }
        return fetchResult.count
    }

    // MARK: - 内部筛选查询

    /// 根据筛选条件获取 PHAsset 数组（内部方法，后台线程调用）
    private static func fetchFilteredPHAssets(mode: CleanMode, filter: FilterCriteria) -> [PHAsset] {
        let mediaType: PHAssetMediaType = mode == .photo ? .image : .video

        // 如果指定了相册，从相册中获取
        if let albumIds = filter.albumIdentifiers, !albumIds.isEmpty {
            var assetIds = Set<String>()
            for albumId in albumIds {
                let collections = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [albumId], options: nil
                )
                collections.enumerateObjects { collection, _, _ in
                    let fetchOptions = PHFetchOptions()
                    var predicates: [NSPredicate] = [
                        NSPredicate(format: "mediaType == %d", mediaType.rawValue)
                    ]
                    Self.addFilterPredicates(to: &predicates, filter: filter)
                    fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

                    let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    result.enumerateObjects { asset, _, _ in
                        assetIds.insert(asset.localIdentifier)
                    }
                }
            }

            // 用 identifiers 获取去重后的 assets
            guard !assetIds.isEmpty else { return [] }
            let result = PHAsset.fetchAssets(withLocalIdentifiers: Array(assetIds), options: nil)
            var assets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in assets.append(asset) }
            return assets
        }

        // 无相册指定，全局查询
        let options = PHFetchOptions()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "mediaType == %d", mediaType.rawValue)
        ]
        Self.addFilterPredicates(to: &predicates, filter: filter)
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let fetchResult = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    /// 将筛选条件转为 NSPredicate 追加到数组
    private static func addFilterPredicates(to predicates: inout [NSPredicate], filter: FilterCriteria) {
        if let startDate = filter.startDate {
            predicates.append(NSPredicate(format: "creationDate >= %@", startDate as NSDate))
        }
        if let endDate = filter.endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", endDate as NSDate))
        }
        if filter.screenshotsOnly {
            predicates.append(NSPredicate(
                format: "(mediaSubtypes & %d) != 0",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            ))
        }
    }

    // MARK: - 文件大小

    static func getFileSize(for asset: PHAsset?) -> Int64 {
        guard let asset = asset else { return 0 }
        let resources = PHAssetResource.assetResources(for: asset)
        let primaryTypes: Set<PHAssetResourceType> = [.photo, .video, .fullSizePhoto, .fullSizeVideo]
        guard let resource = resources.first(where: { primaryTypes.contains($0.type) }) ?? resources.first else { return 0 }
        if let size = resource.value(forKey: "fileSize") as? Int64 { return size }
        return 0
    }

    // MARK: - 图片加载

    private let imageManager = PHCachingImageManager()

    /// 增强的图片请求方法，支持 iCloud 下载进度回调
    @discardableResult
    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (UIImage?, ImageLoadError?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        if let progressHandler = progressHandler {
            options.progressHandler = { progress, _, _, _ in
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            }
        }

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if isDegraded && image != nil {
                return
            }
            if let image = image {
                completion(image, nil)
            } else {
                let error = info?[PHImageErrorKey] as? NSError
                if error != nil {
                    completion(nil, .iCloudDownloadFailed)
                } else {
                    completion(nil, .unknown)
                }
            }
        }
    }

    /// 便利方法 — 保持原有 API 签名和降级缩略图行为
    @discardableResult
    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if image != nil || !isDegraded {
                completion(image)
            }
        }
    }

    /// 取消图片请求
    func cancelImageRequest(_ requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }

    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(
            for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil
        )
    }

    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(
            for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil
        )
    }

    func stopAllCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Limited Access

    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController) { _ in }
    }
}
