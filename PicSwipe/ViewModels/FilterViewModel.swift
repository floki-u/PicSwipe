// PicSwipe/ViewModels/FilterViewModel.swift
import Foundation
import Observation

/// 时间范围预设
enum TimePreset: String, CaseIterable {
    case all = "全部"
    case oneYear = "1年前"
    case twoYears = "2年前"
    case threeYears = "3年前"
    case custom = "自定义"
}

/// 筛选页视图模型 — 管理筛选条件状态和匹配数量
@Observable
final class FilterViewModel {

    // MARK: - 筛选状态

    var screenshotsOnly: Bool = false
    var largeFilesOnly: Bool = false
    var selectedTimePreset: TimePreset = .all
    var customStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    var selectedAlbumIds: Set<String> = []

    // MARK: - 数据状态

    var albums: [AlbumInfo] = []
    var matchingCount: Int = 0
    var isLoadingCount: Bool = false
    var isLoadingAlbums: Bool = false
    var mode: CleanMode = .photo

    // MARK: - 防抖

    private var countTask: Task<Void, Never>?

    // MARK: - 数据加载

    /// 加载相册列表
    @MainActor
    func loadAlbums(photoService: PhotoLibraryService) async {
        isLoadingAlbums = true
        let mediaType = mode == .photo ? Photos.PHAssetMediaType.image : .video
        albums = await photoService.fetchAlbums(for: mediaType)
        isLoadingAlbums = false
    }

    /// 防抖更新匹配数（0.3s 延迟，避免频繁查询）
    @MainActor
    func updateMatchingCount(photoService: PhotoLibraryService) {
        countTask?.cancel()
        isLoadingCount = true
        countTask = Task {
            // 防抖延迟
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            let filter = buildFilter()
            if filter.hasActiveFilter {
                let count = await photoService.fetchFilteredAssetCount(mode: mode, filter: filter)
                guard !Task.isCancelled else { return }
                matchingCount = count
            } else {
                let mediaType = mode == .photo ? Photos.PHAssetMediaType.image : .video
                let count = await photoService.fetchAssetCount(for: mediaType)
                guard !Task.isCancelled else { return }
                matchingCount = count
            }
            isLoadingCount = false
        }
    }

    // MARK: - 操作

    func toggleScreenshots() {
        screenshotsOnly.toggle()
        if screenshotsOnly {
            // 截图模式自动切换到照片
            mode = .photo
        }
    }

    func toggleLargeFiles() {
        largeFilesOnly.toggle()
    }

    func selectTimePreset(_ preset: TimePreset) {
        selectedTimePreset = preset
    }

    func toggleAlbum(id: String) {
        if selectedAlbumIds.contains(id) {
            selectedAlbumIds.remove(id)
        } else {
            selectedAlbumIds.insert(id)
        }
    }

    func resetAll() {
        screenshotsOnly = false
        largeFilesOnly = false
        selectedTimePreset = .all
        selectedAlbumIds = []
    }

    // MARK: - 构建筛选条件

    func buildFilter() -> FilterCriteria {
        var filter = FilterCriteria()

        // 截图
        filter.screenshotsOnly = screenshotsOnly

        // 大文件
        filter.largeFilesOnly = largeFilesOnly
        if largeFilesOnly {
            filter.sortBySize = true
        }

        // 时间范围
        switch selectedTimePreset {
        case .all:
            break
        case .oneYear:
            filter.endDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        case .twoYears:
            filter.endDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
        case .threeYears:
            filter.endDate = Calendar.current.date(byAdding: .year, value: -3, to: Date())
        case .custom:
            filter.endDate = customStartDate
        }

        // 相册
        if !selectedAlbumIds.isEmpty {
            filter.albumIdentifiers = Array(selectedAlbumIds)
        }

        return filter
    }
}

import Photos
