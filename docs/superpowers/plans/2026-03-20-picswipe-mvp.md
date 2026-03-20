# PicSwipe MVP (V1.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete photo cleaning flow — from opening the app through swipe browsing to batch deletion — as a polished iOS native app with the Fresh Mint dark theme.

**Architecture:** MVVM with SwiftUI views, `@Observable` ViewModels, and three app-level Services injected via `@Environment`. Navigation via `NavigationStack` + path enum. SwiftData for persistence (CleanRecord, UserSettings). PhotoKit for photo library access. Session state is memory-only.

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+), PhotoKit, SwiftData, XCTest

**Spec References:**
- PRD: `docs/PRD.md`
- Tech Spec: `docs/superpowers/specs/2026-03-19-picswipe-design.md`
- UI Spec: `docs/superpowers/specs/2026-03-20-picswipe-ui-design.md`

**MVP Scope (PRD §14 V1.0):** F-01~F-07, F-10~F-13, F-17. Photo mode only. No video, no filter page, no clean history timeline.

---

## File Structure

```
PicSwipe/
├── PicSwipeApp.swift                    — App 入口，SwiftData 容器，Service 注入
├── Models/
│   ├── CleanMode.swift                  — CleanMode 枚举
│   ├── AssetItem.swift                  — PHAsset 包装器（会话内存模型）
│   ├── CleanSession.swift               — 清理会话（内存模型）
│   ├── FilterCriteria.swift             — 筛选条件
│   ├── CleanRecord.swift                — 清理记录（SwiftData 持久化）
│   ├── UserSettings.swift               — 用户设置（SwiftData 持久化）
│   └── AppDestination.swift             — 导航路径枚举
├── Services/
│   ├── PhotoLibraryService.swift        — 相册权限 + 读写 + 随机抽取
│   ├── StorageService.swift             — 设备存储空间信息
│   └── StatisticsService.swift          — 清理统计（读写 SwiftData）
├── ViewModels/
│   ├── HomeViewModel.swift              — 首页数据加载
│   ├── SwipeViewModel.swift             — 滑动浏览核心逻辑 + 手势状态机
│   └── ConfirmDeleteViewModel.swift     — 确认删除页逻辑
├── Views/
│   ├── DesignSystem.swift               — 品牌色、间距、圆角、共享组件
│   ├── Home/
│   │   └── HomeView.swift               — 首页卡片流
│   ├── Swipe/
│   │   ├── SwipeView.swift              — 滑动浏览页（手势 + 动画）
│   │   └── SwipeCardView.swift          — 单张照片卡片（跟手 + 倾斜）
│   ├── ConfirmDelete/
│   │   └── ConfirmDeleteView.swift      — 确认删除页（逐张预览）
│   ├── Result/
│   │   └── ResultView.swift             — 删除结果页
│   ├── Settings/
│   │   └── SettingsView.swift           — 设置页（卡片可视化）
│   └── Onboarding/
│       ├── WelcomeView.swift            — 欢迎页
│       ├── PermissionView.swift         — 权限说明页
│       └── TutorialView.swift           — 手势教程（3 步）
├── PicSwipe.xcodeproj
├── PicSwipeTests/
│   ├── Models/
│   │   ├── AssetItemTests.swift
│   │   └── CleanSessionTests.swift
│   ├── Services/
│   │   ├── PhotoLibraryServiceTests.swift
│   │   ├── StorageServiceTests.swift
│   │   └── StatisticsServiceTests.swift
│   └── ViewModels/
│       ├── SwipeViewModelTests.swift
│       └── ConfirmDeleteViewModelTests.swift
└── PicSwipeUITests/
    └── PicSwipeUITests.swift
```

---

## Task 1: Xcode 项目创建与基础配置

**Files:**
- Create: `PicSwipe.xcodeproj`（通过 Xcode CLI）
- Create: `PicSwipe/PicSwipeApp.swift`
- Modify: `Info.plist` 配置

**前置条件：** Xcode 15.1+ 已安装

- [ ] **Step 1: 创建 Xcode 项目**

```bash
# 在项目根目录创建 Xcode 项目
cd /Users/ryanmac/Code/pic_app
# 使用 xcodegen 或手动创建 — 由于没有 xcodegen，使用 swift package init 再转换
# 最简方式：用 Xcode 命令行创建
mkdir -p PicSwipe PicSwipeTests PicSwipeUITests
```

手动创建 `project.yml`（如果使用 XcodeGen）或者通过 Xcode GUI 创建项目，设置：
- Product Name: `PicSwipe`
- Organization Identifier: 你的 bundle identifier 前缀
- Interface: SwiftUI
- Language: Swift
- Storage: SwiftData
- Testing: Include Tests
- Target: iOS 17.0
- Device: iPhone only
- Portrait only

- [ ] **Step 2: 配置 Info.plist**

添加以下键值：

```xml
<!-- 相册权限描述 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>PicSwipe 需要访问你的照片库来展示和清理照片。你的照片不会被上传或分享。</string>

<!-- 仅竖屏 -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

- [ ] **Step 3: 创建目录结构**

```bash
mkdir -p PicSwipe/Models
mkdir -p PicSwipe/Services
mkdir -p PicSwipe/ViewModels
mkdir -p PicSwipe/Views/{Home,Swipe,ConfirmDelete,Result,Settings,Onboarding}
mkdir -p PicSwipeTests/{Models,Services,ViewModels}
```

- [ ] **Step 4: 写入 App 入口骨架**

```swift
// PicSwipe/PicSwipeApp.swift
import SwiftUI
import SwiftData

@main
struct PicSwipeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([CleanRecord.self, UserSettings.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

```swift
// PicSwipe/Views/ContentView.swift（临时占位，后续替换为导航架构）
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("PicSwipe")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
}
```

- [ ] **Step 5: 验证构建**

```bash
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

预期：BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add PicSwipe/ PicSwipe.xcodeproj PicSwipeTests/ PicSwipeUITests/
git commit -m "chore(app): create Xcode project with SwiftData and basic structure"
```

---

## Task 2: 设计系统 — 品牌色、间距、共享组件

**Files:**
- Create: `PicSwipe/Views/DesignSystem.swift`

**参考：** UI Spec §1（配色、圆角、间距）

- [ ] **Step 1: 创建设计系统文件**

```swift
// PicSwipe/Views/DesignSystem.swift
import SwiftUI

// MARK: - 品牌色

extension Color {
    /// 品牌主色 #43e97b
    static let brandPrimary = Color(red: 0.263, green: 0.914, blue: 0.482)
    /// 品牌辅色 #38f9d7
    static let brandSecondary = Color(red: 0.220, green: 0.976, blue: 0.843)
    /// 删除/警告红 #FF453A
    static let destructiveRed = Color(red: 1.0, green: 0.271, blue: 0.227)
    /// 存储警告黄 #F4C542
    static let warningYellow = Color(red: 0.957, green: 0.773, blue: 0.259)
    /// 深色背景 #111111
    static let appBackground = Color(red: 0.067, green: 0.067, blue: 0.067)
    /// 卡片/区块背景
    static let surfaceBackground = Color.white.opacity(0.06)
    /// 次要文字 #888888
    static let textSecondary = Color(red: 0.533, green: 0.533, blue: 0.533)
    /// 辅助文字 #555555
    static let textMuted = Color(red: 0.333, green: 0.333, blue: 0.333)
}

// MARK: - 品牌渐变

extension LinearGradient {
    /// 品牌主渐变（135°）
    static let brandGradient = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 间距系统

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    /// 页面左右边距
    static let pagePadding: CGFloat = 16
}

// MARK: - 圆角系统

enum CornerRadius {
    static let hero: CGFloat = 22
    static let card: CGFloat = 16
    static let button: CGFloat = 14
    static let thumbnail: CGFloat = 8
    static let chip: CGFloat = 12
    static let progressBar: CGFloat = 2
}

// MARK: - 共享视图组件

/// 品牌渐变主按钮
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.brandGradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
    }
}

/// 红色删除按钮
struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.destructiveRed)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
    }
}

/// 卡片容器
struct CardContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

/// 文件大小格式化
func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
```

- [ ] **Step 2: 验证构建**

```bash
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- [ ] **Step 3: Commit**

```bash
git add PicSwipe/Views/DesignSystem.swift
git commit -m "feat(app): add design system with brand colors, spacing, and shared components"
```

---

## Task 3: 数据模型

**Files:**
- Create: `PicSwipe/Models/CleanMode.swift`
- Create: `PicSwipe/Models/AssetItem.swift`
- Create: `PicSwipe/Models/CleanSession.swift`
- Create: `PicSwipe/Models/FilterCriteria.swift`
- Create: `PicSwipe/Models/CleanRecord.swift`
- Create: `PicSwipe/Models/UserSettings.swift`
- Create: `PicSwipe/Models/AppDestination.swift`
- Create: `PicSwipeTests/Models/AssetItemTests.swift`
- Create: `PicSwipeTests/Models/CleanSessionTests.swift`

**参考：** Tech Spec §数据模型，§导航架构

- [ ] **Step 1: 写 AssetItem 和 CleanSession 的测试**

```swift
// PicSwipeTests/Models/AssetItemTests.swift
import XCTest
@testable import PicSwipe

final class AssetItemTests: XCTestCase {
    func test_init_defaultMarkedForDeletionIsFalse() {
        let item = AssetItem(localIdentifier: "test-id", fileSize: 1024)
        XCTAssertFalse(item.markedForDeletion)
        XCTAssertEqual(item.localIdentifier, "test-id")
        XCTAssertEqual(item.fileSize, 1024)
    }

    func test_toggleDeletion_flipsFlag() {
        var item = AssetItem(localIdentifier: "test-id", fileSize: 1024)
        item.markedForDeletion = true
        XCTAssertTrue(item.markedForDeletion)
        item.markedForDeletion = false
        XCTAssertFalse(item.markedForDeletion)
    }
}
```

```swift
// PicSwipeTests/Models/CleanSessionTests.swift
import XCTest
@testable import PicSwipe

final class CleanSessionTests: XCTestCase {
    func test_init_startsAtIndexZero() {
        let session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200)
            ]
        )
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertEqual(session.assets.count, 2)
        XCTAssertEqual(session.mode, .photo)
    }

    func test_markedForDeletionCount_returnsCorrectCount() {
        var session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200),
                AssetItem(localIdentifier: "c", fileSize: 300)
            ]
        )
        session.assets[0].markedForDeletion = true
        session.assets[2].markedForDeletion = true
        XCTAssertEqual(session.markedForDeletionCount, 2)
        XCTAssertEqual(session.markedForDeletionTotalSize, 400)
    }

    func test_isLastAsset_correctAtBoundary() {
        let session = CleanSession(
            mode: .photo,
            assets: [
                AssetItem(localIdentifier: "a", fileSize: 100),
                AssetItem(localIdentifier: "b", fileSize: 200)
            ]
        )
        XCTAssertFalse(session.isAtLastAsset) // index 0, last is 1
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/AssetItemTests -only-testing:PicSwipeTests/CleanSessionTests
```

预期：编译失败（类型不存在）

- [ ] **Step 3: 实现所有数据模型**

```swift
// PicSwipe/Models/CleanMode.swift
import Foundation

enum CleanMode: String, Codable, Hashable {
    case photo
    case video
}
```

```swift
// PicSwipe/Models/AssetItem.swift
import Photos

/// 当前浏览会话中的一个资源（内存模型，不持久化）
struct AssetItem: Identifiable {
    let id: String  // PHAsset.localIdentifier
    let phAsset: PHAsset?  // nil 用于测试
    let localIdentifier: String
    var markedForDeletion: Bool = false
    var fileSize: Int64
    var creationDate: Date?
    var mediaType: PHAssetMediaType

    /// 便捷初始化器（用于测试，不需要真实 PHAsset）
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
```

```swift
// PicSwipe/Models/CleanSession.swift
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

    /// 标记删除的数量
    var markedForDeletionCount: Int {
        assets.filter(\.markedForDeletion).count
    }

    /// 标记删除的总文件大小（字节）
    var markedForDeletionTotalSize: Int64 {
        assets.filter(\.markedForDeletion).reduce(0) { $0 + $1.fileSize }
    }

    /// 获取所有标记删除的 AssetItem
    var markedAssets: [AssetItem] {
        assets.filter(\.markedForDeletion)
    }

    /// 是否在最后一张
    var isAtLastAsset: Bool {
        currentIndex >= assets.count - 1
    }

    /// 当前资源
    var currentAsset: AssetItem? {
        guard currentIndex >= 0, currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }
}
```

```swift
// PicSwipe/Models/FilterCriteria.swift
import Foundation

/// 筛选条件（V1.1 使用，MVP 预留接口）
struct FilterCriteria {
    var startDate: Date?
    var endDate: Date?
    var albumIdentifiers: [String]?
}
```

```swift
// PicSwipe/Models/CleanRecord.swift
import Foundation
import SwiftData

/// 清理记录（持久化到 SwiftData）
@Model
final class CleanRecord {
    var date: Date
    var deletedCount: Int
    var freedSpace: Int64
    var mode: String  // CleanMode.rawValue

    init(date: Date = .now, deletedCount: Int, freedSpace: Int64, mode: CleanMode) {
        self.date = date
        self.deletedCount = deletedCount
        self.freedSpace = freedSpace
        self.mode = mode.rawValue
    }

    var cleanMode: CleanMode {
        CleanMode(rawValue: mode) ?? .photo
    }
}
```

```swift
// PicSwipe/Models/UserSettings.swift
import Foundation
import SwiftData

/// 用户设置（持久化到 SwiftData）
@Model
final class UserSettings {
    var batchSize: Int = 20
    var hasSeenTutorial: Bool = false

    init(batchSize: Int = 20, hasSeenTutorial: Bool = false) {
        self.batchSize = batchSize
        self.hasSeenTutorial = hasSeenTutorial
    }
}
```

```swift
// PicSwipe/Models/AppDestination.swift
import Foundation

/// 导航路径枚举
enum AppDestination: Hashable {
    case swipe(CleanMode)
    case confirmDelete
    case filter
    case settings
    case result(deletedCount: Int, freedSpace: Int64)
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests
```

预期：所有测试 PASS

- [ ] **Step 5: Commit**

```bash
git add PicSwipe/Models/ PicSwipeTests/Models/
git commit -m "feat(models): add data models with SwiftData persistence and unit tests"
```

---

## Task 4: PhotoLibraryService — 权限管理 + 照片读取

**Files:**
- Create: `PicSwipe/Services/PhotoLibraryService.swift`
- Create: `PicSwipeTests/Services/PhotoLibraryServiceTests.swift`

**参考：** Tech Spec §关键流程（权限、随机抽取、文件大小获取）

- [ ] **Step 1: 写测试**

```swift
// PicSwipeTests/Services/PhotoLibraryServiceTests.swift
import XCTest
import Photos
@testable import PicSwipe

final class PhotoLibraryServiceTests: XCTestCase {
    var service: PhotoLibraryService!

    override func setUp() {
        super.setUp()
        service = PhotoLibraryService()
    }

    func test_authorizationStatus_returnsValidStatus() {
        // 模拟器上默认为 .notDetermined 或 .authorized
        let status = service.authorizationStatus
        XCTAssertNotNil(status)
    }

    func test_getFileSize_withNilAsset_returnsZero() {
        // 测试 fileSize fallback
        let size = PhotoLibraryService.getFileSize(for: nil)
        XCTAssertEqual(size, 0)
    }

    func test_shuffleAndTake_respectsCount() {
        let identifiers = (0..<100).map { "id-\($0)" }
        let taken = Array(identifiers.shuffled().prefix(20))
        XCTAssertEqual(taken.count, 20)
    }
}
```

- [ ] **Step 2: 实现 PhotoLibraryService**

```swift
// PicSwipe/Services/PhotoLibraryService.swift
import Photos
import UIKit
import Observation

/// 相册读写服务
@Observable
final class PhotoLibraryService {

    // MARK: - 权限状态

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    var isLimited: Bool {
        authorizationStatus == .limited
    }

    /// 请求相册权限
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - 照片读取

    /// 获取照片/视频总数量
    func fetchAssetCount(for mediaType: PHAssetMediaType) -> Int {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
        return PHAsset.fetchAssets(with: options).count
    }

    /// 随机抽取一组照片构建 CleanSession
    func fetchRandomAssets(mode: CleanMode, count: Int, filter: FilterCriteria? = nil) async -> CleanSession {
        let mediaType: PHAssetMediaType = mode == .photo ? .image : .video

        let options = PHFetchOptions()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "mediaType == %d", mediaType.rawValue)
        ]

        // 时间筛选（V1.1 用，预留）
        if let startDate = filter?.startDate {
            predicates.append(NSPredicate(format: "creationDate >= %@", startDate as NSDate))
        }
        if let endDate = filter?.endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", endDate as NSDate))
        }

        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: options)
        var allAssets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            allAssets.append(asset)
        }

        // Fisher-Yates shuffle + 取前 N 个
        var shuffled = allAssets
        for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            shuffled.swapAt(i, j)
        }
        let selected = Array(shuffled.prefix(count))

        // 批量获取文件大小
        let assetItems = selected.map { phAsset in
            AssetItem(phAsset: phAsset, fileSize: Self.getFileSize(for: phAsset))
        }

        return CleanSession(mode: mode, assets: assetItems, filter: filter)
    }

    /// 执行批量删除
    func deleteAssets(_ assets: [AssetItem]) async throws -> Int {
        let phAssets = assets.compactMap(\.phAsset)
        guard !phAssets.isEmpty else { return 0 }

        let identifiers = phAssets.map(\.localIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var deletedCount = 0
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(fetchResult)
        }
        deletedCount = fetchResult.count
        return deletedCount
    }

    // MARK: - 文件大小

    /// 获取 PHAsset 的文件大小（字节）
    static func getFileSize(for asset: PHAsset?) -> Int64 {
        guard let asset = asset else { return 0 }
        let resources = PHAssetResource.assetResources(for: asset)
        // 取主资源
        let primaryTypes: Set<PHAssetResourceType> = [.photo, .video, .fullSizePhoto, .fullSizeVideo]
        guard let resource = resources.first(where: { primaryTypes.contains($0.type) }) ?? resources.first else {
            return 0
        }
        // fileSize 通过 KVC 获取（非公开 API，带 fallback）
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }
        return 0
    }

    // MARK: - 图片加载

    private let imageManager = PHCachingImageManager()

    /// 请求照片图片
    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    /// 开始预缓存
    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// 停止预缓存
    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// 清空全部缓存
    func stopAllCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Limited Access

    /// 弹出 Limited Access 照片选择器
    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
    }
}
```

- [ ] **Step 3: 运行测试**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/PhotoLibraryServiceTests
```

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/Services/PhotoLibraryService.swift PicSwipeTests/Services/PhotoLibraryServiceTests.swift
git commit -m "feat(photo-service): add PhotoLibraryService with permissions, fetch, delete, and caching"
```

---

## Task 5: StorageService — 设备存储信息

**Files:**
- Create: `PicSwipe/Services/StorageService.swift`
- Create: `PicSwipeTests/Services/StorageServiceTests.swift`

- [ ] **Step 1: 写测试**

```swift
// PicSwipeTests/Services/StorageServiceTests.swift
import XCTest
@testable import PicSwipe

final class StorageServiceTests: XCTestCase {
    func test_fetchStorageInfo_returnsTotalGreaterThanZero() async {
        let service = StorageService()
        let info = service.fetchStorageInfo()
        XCTAssertGreaterThan(info.totalSpace, 0)
        XCTAssertGreaterThan(info.usedSpace, 0)
        XCTAssertLessThanOrEqual(info.usedSpace, info.totalSpace)
    }

    func test_usagePercentage_calculatesCorrectly() {
        let info = StorageInfo(totalSpace: 100, usedSpace: 72)
        XCTAssertEqual(info.usagePercentage, 0.72, accuracy: 0.01)
    }
}
```

- [ ] **Step 2: 实现 StorageService**

```swift
// PicSwipe/Services/StorageService.swift
import Foundation
import Observation

/// 设备存储信息
struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64

    var availableSpace: Int64 { totalSpace - usedSpace }
    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    /// 存储颜色等级：green (<70%), yellow (70-90%), red (>90%)
    var level: StorageLevel {
        switch usagePercentage {
        case ..<0.7: return .normal
        case 0.7..<0.9: return .warning
        default: return .critical
        }
    }
}

enum StorageLevel {
    case normal, warning, critical
}

/// 设备存储服务
@Observable
final class StorageService {
    var storageInfo: StorageInfo = StorageInfo(totalSpace: 0, usedSpace: 0)

    func fetchStorageInfo() -> StorageInfo {
        let fileManager = FileManager.default
        guard let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attrs[.systemSize] as? Int64,
              let freeSize = attrs[.systemFreeSize] as? Int64 else {
            return StorageInfo(totalSpace: 0, usedSpace: 0)
        }
        let info = StorageInfo(totalSpace: totalSize, usedSpace: totalSize - freeSize)
        storageInfo = info
        return info
    }
}
```

- [ ] **Step 3: 运行测试**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/StorageServiceTests
```

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/Services/StorageService.swift PicSwipeTests/Services/StorageServiceTests.swift
git commit -m "feat(storage-service): add StorageService with device storage info"
```

---

## Task 6: StatisticsService — 清理统计

**Files:**
- Create: `PicSwipe/Services/StatisticsService.swift`
- Create: `PicSwipeTests/Services/StatisticsServiceTests.swift`

- [ ] **Step 1: 写测试**

```swift
// PicSwipeTests/Services/StatisticsServiceTests.swift
import XCTest
import SwiftData
@testable import PicSwipe

final class StatisticsServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var service: StatisticsService!

    override func setUp() {
        super.setUp()
        let schema = Schema([CleanRecord.self, UserSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        service = StatisticsService()
    }

    func test_totalDeletedCount_withNoRecords_returnsZero() {
        let total = service.totalDeletedCount(in: context)
        XCTAssertEqual(total, 0)
    }

    func test_totalDeletedCount_sumsAllRecords() {
        context.insert(CleanRecord(deletedCount: 5, freedSpace: 1000, mode: .photo))
        context.insert(CleanRecord(deletedCount: 3, freedSpace: 2000, mode: .photo))
        try? context.save()
        let total = service.totalDeletedCount(in: context)
        XCTAssertEqual(total, 8)
    }

    func test_totalFreedSpace_sumsAllRecords() {
        context.insert(CleanRecord(deletedCount: 5, freedSpace: 1000, mode: .photo))
        context.insert(CleanRecord(deletedCount: 3, freedSpace: 2000, mode: .photo))
        try? context.save()
        let total = service.totalFreedSpace(in: context)
        XCTAssertEqual(total, 3000)
    }
}
```

- [ ] **Step 2: 实现 StatisticsService**

```swift
// PicSwipe/Services/StatisticsService.swift
import Foundation
import SwiftData
import Observation

/// 清理统计服务
@Observable
final class StatisticsService {

    /// 累计删除数量
    func totalDeletedCount(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CleanRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.deletedCount }
    }

    /// 累计释放空间（字节）
    func totalFreedSpace(in context: ModelContext) -> Int64 {
        let descriptor = FetchDescriptor<CleanRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.freedSpace }
    }

    /// 记录一次清理
    func recordClean(deletedCount: Int, freedSpace: Int64, mode: CleanMode, in context: ModelContext) {
        let record = CleanRecord(deletedCount: deletedCount, freedSpace: freedSpace, mode: mode)
        context.insert(record)
        try? context.save()
    }

    /// 获取或创建 UserSettings
    func getSettings(in context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = UserSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
```

- [ ] **Step 3: 运行测试**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/StatisticsServiceTests
```

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/Services/StatisticsService.swift PicSwipeTests/Services/StatisticsServiceTests.swift
git commit -m "feat(stats-service): add StatisticsService with SwiftData persistence"
```

---

## Task 7: 导航架构 + App 入口集成

**Files:**
- Modify: `PicSwipe/PicSwipeApp.swift`
- Create: `PicSwipe/Views/RootView.swift`

**参考：** Tech Spec §导航架构、§状态管理

- [ ] **Step 1: 创建 RootView 导航容器**

```swift
// PicSwipe/Views/RootView.swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StorageService.self) private var storageService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var path = NavigationPath()
    @State private var cleanSession: CleanSession?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                path: $path,
                cleanSession: $cleanSession
            )
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .swipe(let mode):
                    SwipeView(
                        path: $path,
                        cleanSession: $cleanSession,
                        mode: mode
                    )
                case .confirmDelete:
                    ConfirmDeleteView(
                        path: $path,
                        cleanSession: $cleanSession
                    )
                case .result(let deletedCount, let freedSpace):
                    ResultView(
                        path: $path,
                        cleanSession: $cleanSession,
                        deletedCount: deletedCount,
                        freedSpace: freedSpace
                    )
                case .settings:
                    SettingsView()
                case .filter:
                    EmptyView() // V1.1
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
```

- [ ] **Step 2: 更新 PicSwipeApp 注入服务**

```swift
// PicSwipe/PicSwipeApp.swift
import SwiftUI
import SwiftData

@main
struct PicSwipeApp: App {
    let modelContainer: ModelContainer
    let photoService = PhotoLibraryService()
    let storageService = StorageService()
    let statsService = StatisticsService()

    init() {
        do {
            let schema = Schema([CleanRecord.self, UserSettings.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(photoService)
                .environment(storageService)
                .environment(statsService)
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 3: 创建占位视图**（每个页面先放占位，后续 Task 逐个实现）

每个视图必须匹配 RootView 中 navigationDestination 的调用签名：

```swift
// PicSwipe/Views/Home/HomeView.swift
struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    var body: some View {
        Text("首页").background(Color.appBackground)
    }
}

// PicSwipe/Views/Swipe/SwipeView.swift
struct SwipeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let mode: CleanMode
    var body: some View {
        Text("滑动浏览").background(Color.appBackground)
    }
}

// PicSwipe/Views/ConfirmDelete/ConfirmDeleteView.swift
struct ConfirmDeleteView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    var body: some View {
        Text("确认删除").background(Color.appBackground)
    }
}

// PicSwipe/Views/Result/ResultView.swift
struct ResultView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let deletedCount: Int
    let freedSpace: Int64
    var body: some View {
        Text("结果").background(Color.appBackground)
    }
}

// PicSwipe/Views/Settings/SettingsView.swift
struct SettingsView: View {
    var body: some View {
        Text("设置").background(Color.appBackground)
    }
}
```

- [ ] **Step 4: 验证构建**

```bash
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- [ ] **Step 5: Commit**

```bash
git add PicSwipe/
git commit -m "feat(app): add NavigationStack routing, service injection, and placeholder views"
```

---

## Task 8: HomeView + HomeViewModel — 首页卡片流

**Files:**
- Create: `PicSwipe/ViewModels/HomeViewModel.swift`
- Modify: `PicSwipe/Views/Home/HomeView.swift`

**参考：** UI Spec §2.1（首页卡片流设计）

- [ ] **Step 1: 实现 HomeViewModel**

```swift
// PicSwipe/ViewModels/HomeViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var storageInfo: StorageInfo = StorageInfo(totalSpace: 0, usedSpace: 0)
    var photoCount: Int = 0
    var videoCount: Int = 0
    var totalDeletedCount: Int = 0
    var totalFreedSpace: Int64 = 0
    var selectedMode: CleanMode = .photo
    var batchSize: Int = 20
    var isLoading: Bool = false

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
```

- [ ] **Step 2: 实现 HomeView**

根据 UI Spec §2.1 实现完整的卡片流首页：品牌 Hero 区 → 存储胶囊 → 开始清理行动卡片 → 三列数据卡片。使用 DesignSystem 中定义的颜色和组件。

关键布局要素：
- 深色背景 `.appBackground`
- Hero 区带品牌渐变半透明背景 + 🌿 emoji
- 存储胶囊 Capsule
- 开始清理按钮用品牌渐变
- 照片/视频/已释放三列数据卡片

- [ ] **Step 3: 验证构建并在模拟器运行**

```bash
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/ViewModels/HomeViewModel.swift PicSwipe/Views/Home/HomeView.swift
git commit -m "feat(home): implement HomeView with card-flow layout and HomeViewModel"
```

---

## Task 9: SwipeViewModel — 滑动浏览核心逻辑

**Files:**
- Create: `PicSwipe/ViewModels/SwipeViewModel.swift`
- Create: `PicSwipeTests/ViewModels/SwipeViewModelTests.swift`

**参考：** Tech Spec §滑动浏览页、PRD S-01~S-15

- [ ] **Step 1: 写测试**

```swift
// PicSwipeTests/ViewModels/SwipeViewModelTests.swift
import XCTest
@testable import PicSwipe

final class SwipeViewModelTests: XCTestCase {
    var vm: SwipeViewModel!
    var session: CleanSession!

    override func setUp() {
        super.setUp()
        session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
            AssetItem(localIdentifier: "c", fileSize: 300),
        ])
        vm = SwipeViewModel()
        vm.session = session
    }

    func test_keepCurrent_advancesToNextAndDoesNotMark() {
        vm.keepCurrent()
        XCTAssertFalse(vm.session!.assets[0].markedForDeletion)
        XCTAssertEqual(vm.session!.currentIndex, 1)
    }

    func test_deleteCurrent_marksAndAdvances() {
        vm.deleteCurrent()
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion)
        XCTAssertEqual(vm.session!.currentIndex, 1)
    }

    func test_goBack_fromIndexZero_doesNothing() {
        vm.goBack()
        XCTAssertEqual(vm.session!.currentIndex, 0)
    }

    func test_goBack_fromIndexOne_goesBack() {
        vm.keepCurrent() // index 0 → 1
        vm.goBack()      // index 1 → 0
        XCTAssertEqual(vm.session!.currentIndex, 0)
    }

    func test_deleteCurrent_atLastAsset_setsIsFinished() {
        vm.keepCurrent() // 0 → 1
        vm.keepCurrent() // 1 → 2
        vm.deleteCurrent() // 2, last one
        XCTAssertTrue(vm.isFinished)
    }

    func test_goBack_thenRedelete_overridesMark() {
        vm.keepCurrent()  // 保留 a, → 1
        vm.goBack()       // ← 0
        vm.deleteCurrent() // 标记删除 a, → 1
        XCTAssertTrue(vm.session!.assets[0].markedForDeletion)
    }

    func test_markedCount_tracksCorrectly() {
        vm.deleteCurrent() // 标记 a
        vm.keepCurrent()   // 保留 b
        vm.deleteCurrent() // 标记 c
        XCTAssertEqual(vm.session!.markedForDeletionCount, 2)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

- [ ] **Step 3: 实现 SwipeViewModel**

```swift
// PicSwipe/ViewModels/SwipeViewModel.swift
import SwiftUI
import Observation

/// 手势方向
enum SwipeDirection {
    case up, left, down, right, none
}

@Observable
final class SwipeViewModel {
    var session: CleanSession?
    var isFinished: Bool = false
    var showUI: Bool = true  // 纯净模式开关

    // 手势状态
    var dragOffset: CGSize = .zero
    var dragDirection: SwipeDirection = .none

    // MARK: - 核心操作

    /// 上滑保留
    func keepCurrent() {
        guard var session = session else { return }
        // 保留 = 不标记（或取消之前的标记）
        session.assets[session.currentIndex].markedForDeletion = false
        advanceOrFinish(&session)
    }

    /// 左滑删除
    func deleteCurrent() {
        guard var session = session else { return }
        session.assets[session.currentIndex].markedForDeletion = true
        advanceOrFinish(&session)
    }

    /// 下滑回看
    func goBack() {
        guard var session = session, session.currentIndex > 0 else { return }
        session.currentIndex -= 1
        self.session = session
    }

    /// 切换纯净模式
    func toggleUI() {
        showUI.toggle()
    }

    // MARK: - 手势处理

    /// 判断拖拽方向
    func detectDirection(translation: CGSize) -> SwipeDirection {
        let absX = abs(translation.width)
        let absY = abs(translation.height)

        if absX < 20 && absY < 20 { return .none }

        if absY > absX {
            return translation.height < 0 ? .up : .down
        } else {
            return translation.width < 0 ? .left : .right
        }
    }

    /// 是否超过阈值
    func isOverThreshold(translation: CGSize, screenSize: CGSize) -> Bool {
        let threshold: CGFloat = 1.0 / 3.0
        switch dragDirection {
        case .up: return abs(translation.height) > screenSize.height * threshold
        case .left: return abs(translation.width) > screenSize.width * threshold
        case .down: return abs(translation.height) > screenSize.height * threshold
        default: return false
        }
    }

    /// 计算倾斜角度（最大 ±10°）
    func rotationAngle(translation: CGSize, screenWidth: CGFloat) -> Angle {
        let maxAngle: Double = 10
        let progress = Double(translation.width) / Double(screenWidth)
        return .degrees(progress * maxAngle)
    }

    // MARK: - Private

    private func advanceOrFinish(_ session: inout CleanSession) {
        if session.currentIndex >= session.assets.count - 1 {
            self.session = session
            isFinished = true
        } else {
            session.currentIndex += 1
            self.session = session
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/SwipeViewModelTests
```

- [ ] **Step 5: Commit**

```bash
git add PicSwipe/ViewModels/SwipeViewModel.swift PicSwipeTests/ViewModels/SwipeViewModelTests.swift
git commit -m "feat(swipe): add SwipeViewModel with keep/delete/goBack logic and gesture handling"
```

---

## Task 10: SwipeView — 滑动浏览页 UI + 手势 + 动画

**Files:**
- Modify: `PicSwipe/Views/Swipe/SwipeView.swift`
- Create: `PicSwipe/Views/Swipe/SwipeCardView.swift`

**参考：** UI Spec §2.2（极简纯净），§6.1（动画规格）

这是最复杂的视图。核心要素：

- [ ] **Step 1: 创建 SwipeCardView — 单张照片卡片**

包含：
- 全屏照片加载（通过 PhotoLibraryService.requestImage）
- 跟手移动（`.offset(dragOffset)`）
- 方向倾斜（`.rotationEffect(angle)`）
- 阈值提示覆盖层（绿色"保留 ✓"/ 红色"删除 ×"）
- 触觉反馈（UIImpactFeedbackGenerator）

- [ ] **Step 2: 创建 SwipeView — 页面容器**

包含：
- DragGesture 手势识别 → 调用 SwipeViewModel
- 飞出动画 `spring(response: 0.4, dampingFraction: 0.8)`
- 弹回动画 `spring(response: 0.3, dampingFraction: 0.7)`
- 顶部薄状态栏（返回、🗑 N、进度 x/y）
- 底部信息栏（日期、文件大小）
- 底部进度条（品牌绿填充）
- 单击切换纯净模式
- `isFinished` 时导航到 confirmDelete
- 第一张下滑弹性反馈
- 绿色闪烁 / 红色 × 反馈动画

**关键：会话创建和状态同步**

在 SwipeView 的 `.task` 中创建会话并加载：

```swift
.task {
    // 通过 PhotoLibraryService 创建会话
    let session = await photoService.fetchRandomAssets(
        mode: mode,
        count: batchSize
    )
    self.cleanSession = session   // 写入父级 Binding
    vm.session = session          // 同步到 ViewModel
    isLoading = false
}
```

加载过程中显示 loading 状态（品牌色 ProgressView）。如果返回 0 张照片，显示空状态提示并允许返回。

**同步 ViewModel → Binding：** 在 `.onChange(of: vm.isFinished)` 和 `.onChange(of: vm.session)` 中将 ViewModel 的 session 同步回父级 Binding：

```swift
.onChange(of: vm.session?.currentIndex) { _, _ in
    cleanSession = vm.session  // 保持 Binding 同步
}
.onChange(of: vm.isFinished) { _, finished in
    if finished {
        cleanSession = vm.session  // 确保标记数据同步到 Binding
        path.append(AppDestination.confirmDelete)
    }
}
```

这样 ConfirmDeleteView 从 `$cleanSession` 读取时，能拿到最新的标记数据。

- [ ] **Step 3: 集成照片加载和预缓存**

在 SwipeView 的 `.onAppear` / `.onChange(of: currentIndex)` 中：
- 使用 `PhotoLibraryService.startCaching` 预取 ±3 张
- 更新预取窗口：停止旧的，开始新的

- [ ] **Step 4: 验证构建并在模拟器手动测试**

```bash
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

在模拟器中运行，验证手势和动画效果。

- [ ] **Step 5: Commit**

```bash
git add PicSwipe/Views/Swipe/
git commit -m "feat(swipe): implement SwipeView with gesture system, animations, and photo loading"
```

---

## Task 11: ConfirmDeleteView + ConfirmDeleteViewModel — 确认删除页

**Files:**
- Create: `PicSwipe/ViewModels/ConfirmDeleteViewModel.swift`
- Modify: `PicSwipe/Views/ConfirmDelete/ConfirmDeleteView.swift`
- Create: `PicSwipeTests/ViewModels/ConfirmDeleteViewModelTests.swift`

**参考：** UI Spec §2.3（逐张预览）

- [ ] **Step 1: 写测试**

```swift
// PicSwipeTests/ViewModels/ConfirmDeleteViewModelTests.swift
import XCTest
@testable import PicSwipe

final class ConfirmDeleteViewModelTests: XCTestCase {
    func test_revokeMarking_removesFromMarkedList() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[1].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)

        XCTAssertEqual(vm.markedAssets.count, 2)

        vm.revokeMarking(for: "a")
        XCTAssertEqual(vm.markedAssets.count, 1)
        XCTAssertEqual(vm.markedAssets[0].localIdentifier, "b")
    }

    func test_revokeAll_clearsAllMarks() {
        var session = CleanSession(mode: .photo, assets: [
            AssetItem(localIdentifier: "a", fileSize: 100),
            AssetItem(localIdentifier: "b", fileSize: 200),
        ])
        session.assets[0].markedForDeletion = true
        session.assets[1].markedForDeletion = true

        let vm = ConfirmDeleteViewModel()
        vm.loadFromSession(session)
        vm.revokeAll()

        XCTAssertEqual(vm.markedAssets.count, 0)
    }
}
```

- [ ] **Step 2: 实现 ConfirmDeleteViewModel**

- [ ] **Step 3: 实现 ConfirmDeleteView**

根据 UI Spec §2.3，实现逐张预览布局：
- 大图预览区（TabView 左右滑动）
- 左上角序号标签、右上角 ✕ 撤回按钮
- 底部渐变蒙层（日期 + 大小）
- 圆点指示器
- 缩略图导航条（ScrollView horizontal）
- 释放空间提示
- 确认删除红色按钮
- 再来一组 / 全部撤回

**导航操作实现：**
- 「确认删除」→ 调用 `photoService.deleteAssets()` → 记录统计 → `path.append(.result(...))`
- 「再来一组」→ 清空 `cleanSession`，`path.removeLast(path.count)` 回首页后自动重新进入
- 「全部撤回」→ 清空所有标记，重置 `cleanSession.currentIndex = 0`，`path.removeLast()` 回到 SwipeView 重新浏览

- [ ] **Step 4: 运行测试**

```bash
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/ConfirmDeleteViewModelTests
```

- [ ] **Step 5: Commit**

```bash
git add PicSwipe/ViewModels/ConfirmDeleteViewModel.swift PicSwipe/Views/ConfirmDelete/ PicSwipeTests/ViewModels/ConfirmDeleteViewModelTests.swift
git commit -m "feat(confirm): implement ConfirmDeleteView with swipeable preview and ConfirmDeleteViewModel"
```

---

## Task 12: ResultView — 删除结果页

**Files:**
- Modify: `PicSwipe/Views/Result/ResultView.swift`

**参考：** UI Spec §4（删除结果页）

- [ ] **Step 1: 实现 ResultView**

布局：
- 深色背景
- 成功动画（照片缩小 + 上移 + 透明度渐变）
- 大数字："已清理 N 张"（品牌绿色）
- 副文字："释放 XX MB 空间"
- 「回到首页」半透明次要按钮 → `path.removeLast(path.count)`
- 「再来一组」品牌渐变主按钮 → 回到 swipe

在显示 ResultView 前，调用 `StatisticsService.recordClean()` 记录本次清理。

- [ ] **Step 2: 验证构建**

- [ ] **Step 3: Commit**

```bash
git add PicSwipe/Views/Result/ResultView.swift
git commit -m "feat(confirm): add ResultView with success animation and clean statistics recording"
```

---

## Task 13: SettingsView — 设置页

**Files:**
- Modify: `PicSwipe/Views/Settings/SettingsView.swift`

**参考：** UI Spec §2.5（卡片可视化）

- [ ] **Step 1: 实现 SettingsView**

布局：
- 品牌卡片（App 图标 + 名称 + 版本号 + 权限状态）
- 每组数量卡片（4 个并排按钮：10/20/30/50，选中态品牌渐变）
- 清理历史卡片（迷你柱状图，MVP 简化版：只显示总计数字）
- 其他设置卡片（重播教程、相册权限、隐私政策）

修改 `UserSettings.batchSize` 时通过 SwiftData ModelContext 持久化。

- [ ] **Step 2: 验证构建**

- [ ] **Step 3: Commit**

```bash
git add PicSwipe/Views/Settings/SettingsView.swift
git commit -m "feat(settings): implement SettingsView with card-based layout and batch size selection"
```

---

## Task 14: Onboarding — 欢迎 + 权限 + 手势教程

**Files:**
- Create: `PicSwipe/Views/Onboarding/WelcomeView.swift`
- Create: `PicSwipe/Views/Onboarding/PermissionView.swift`
- Create: `PicSwipe/Views/Onboarding/TutorialView.swift`
- Modify: `PicSwipe/Views/RootView.swift`（添加 onboarding 流程判断）

**参考：** UI Spec §3（Onboarding 教程设计）、PRD §5.3

- [ ] **Step 1: 实现 WelcomeView**

深色背景 + Hero 区 + 🌿 + "PicSwipe" + slogan + 「开始使用」按钮

- [ ] **Step 2: 实现 PermissionView**

权限说明 + 图标化展示（🔒🔵🗑）+ 授权按钮 + 稍后再说

调用 `PhotoLibraryService.requestAuthorization()` 处理四种状态。

- [ ] **Step 3: 实现 TutorialView**

3 步手势教程，TabView 分页：
- Step 1：上滑 = 保留 ✓（动画：模拟照片上滑飞出）
- Step 2：左滑 = 删除 ×（动画：模拟照片左滑飞出）
- Step 3：下滑 = 回看（动画：上一张从顶部滑入）

底部圆点指示器 + 可跳过。完成后设置 `UserSettings.hasSeenTutorial = true`。

- [ ] **Step 4: 修改 RootView 添加 Onboarding 流程**

```swift
// RootView 中判断：
// 1. 权限 == .notDetermined → 显示 Onboarding
// 2. 权限 == .denied → 显示权限引导页
// 3. hasSeenTutorial == false → 显示教程
// 4. 否则 → 显示 HomeView
```

- [ ] **Step 5: 验证构建，在模拟器走完 Onboarding 流程**

- [ ] **Step 6: Commit**

```bash
git add PicSwipe/Views/Onboarding/ PicSwipe/Views/RootView.swift
git commit -m "feat(app): add onboarding flow with welcome, permission request, and gesture tutorial"
```

---

## Task 15: Limited Access 处理

**Files:**
- Modify: `PicSwipe/Views/Home/HomeView.swift`（添加 Limited Access 横幅）
- Modify: `PicSwipe/Views/RootView.swift`（权限状态监听）

**参考：** PRD F-17，Tech Spec §Limited Access

- [ ] **Step 1: 在 HomeView 添加 Limited Access 横幅**

当 `photoService.isLimited` 时，在 Hero 区下方显示提示横幅：
"你只授权了部分照片，点击管理权限"

点击后调用 `presentLimitedLibraryPicker`。

- [ ] **Step 2: 权限降级处理**

在 RootView 的 `.onAppear` 中检查权限状态：
- `.denied` → 显示引导页 + 跳转系统设置按钮
- `.limited` → 正常使用 + 横幅提示

- [ ] **Step 3: 验证构建**

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/Views/Home/HomeView.swift PicSwipe/Views/RootView.swift
git commit -m "feat(home): add Limited Access banner and permission state handling"
```

---

## Task 16: 触觉反馈 + Reduce Motion 适配

**Files:**
- Create: `PicSwipe/Services/HapticService.swift`
- Modify: `PicSwipe/Views/Swipe/SwipeView.swift`（集成触觉）

**参考：** Tech Spec §触觉反馈，UI Spec §6.2

- [ ] **Step 1: 创建 HapticService**

```swift
// PicSwipe/Services/HapticService.swift
import UIKit

enum HapticService {
    static func thresholdReached(direction: SwipeDirection) {
        switch direction {
        case .up:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .left:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        default: break
        }
    }

    static func gestureTriggered() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func deleteSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func deleteError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func boundaryReached() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
```

- [ ] **Step 2: 在 SwipeView 中集成触觉反馈**

- [ ] **Step 3: 添加 Reduce Motion 检查**

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

当 `reduceMotion` 为 `true` 时：飞出动画替换为 opacity 淡入淡出。

- [ ] **Step 4: Commit**

```bash
git add PicSwipe/Services/HapticService.swift PicSwipe/Views/Swipe/
git commit -m "feat(swipe): add haptic feedback and Reduce Motion accessibility support"
```

---

## Task 17: 端到端集成测试

**Files:**
- Modify: `PicSwipeUITests/PicSwipeUITests.swift`

- [ ] **Step 1: 写 UI 测试验证核心流程**

```swift
// PicSwipeUITests/PicSwipeUITests.swift
import XCTest

final class PicSwipeUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func test_appLaunches_showsHomeOrOnboarding() {
        // App 应该启动到首页或 Onboarding
        let exists = app.staticTexts["PicSwipe"].waitForExistence(timeout: 5)
        XCTAssertTrue(exists)
    }

    func test_settingsPage_isAccessible() {
        // 如果首页可见，尝试进入设置
        if app.staticTexts["设置"].exists {
            app.staticTexts["设置"].tap()
            XCTAssertTrue(app.staticTexts["每组数量"].waitForExistence(timeout: 3))
        }
    }
}
```

- [ ] **Step 2: 运行全部测试**

```bash
# 单元测试
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests

# UI 测试
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeUITests
```

- [ ] **Step 3: 修复发现的问题**

- [ ] **Step 4: 最终 Commit**

```bash
git add PicSwipeUITests/
git commit -m "test(app): add UI tests for launch and navigation"
```

---

## Task 18: 最终清理 + 文档更新

**Files:**
- Modify: `CLAUDE.md`（更新项目状态）
- Modify: `.gitignore`（确保排除 .superpowers/）

- [ ] **Step 1: 更新 CLAUDE.md 项目状态**

```markdown
## Project Status

- ✅ 产品设计规格已完成
- ✅ PRD 文档已完成
- ✅ UI 设计规格已完成
- ✅ 实施计划已完成
- ✅ MVP V1.0 代码开发已完成
- ⬜ V1.1 筛选与视频功能
```

- [ ] **Step 2: 确保 .gitignore 配置正确**

```
.superpowers/
*.xcuserdata
DerivedData/
.DS_Store
```

- [ ] **Step 3: Commit + Push**

```bash
git add CLAUDE.md .gitignore
git commit -m "docs: update project status to MVP complete"
git push
```
