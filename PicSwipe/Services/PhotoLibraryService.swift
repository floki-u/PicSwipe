import Photos
import PhotosUI
import UIKit
import Observation

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

    func fetchRandomAssets(mode: CleanMode, count: Int, filter: FilterCriteria? = nil) async -> CleanSession {
        // 在后台线程执行 PhotoKit 读取，避免阻塞主线程
        // 解决 "Missing prefetched properties" 主线程卡顿问题
        let session = await Task.detached(priority: .userInitiated) {
            let mediaType: PHAssetMediaType = mode == .photo ? .image : .video
            let options = PHFetchOptions()
            var predicates: [NSPredicate] = [
                NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            ]
            if let startDate = filter?.startDate {
                predicates.append(NSPredicate(format: "creationDate >= %@", startDate as NSDate))
            }
            if let endDate = filter?.endDate {
                predicates.append(NSPredicate(format: "creationDate <= %@", endDate as NSDate))
            }
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            let fetchResult = PHAsset.fetchAssets(with: options)
            var allAssets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in allAssets.append(asset) }

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
            // 忽略解码失败/iCloud 不可用的情况，回调 nil 由 UI 层处理
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if image != nil || !isDegraded {
                completion(image)
            }
        }
    }

    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
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
