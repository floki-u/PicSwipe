# PicSwipe — iOS 照片/视频快速清理工具

## 概述

PicSwipe 是一款 iOS 原生工具 app，帮助用户通过沉浸式的滑动体验快速清理手机中不需要的照片和视频。核心理念：随机展示、快速决策、批量删除。

## 目标用户

- 普通大众：手机存储不足，想要简单易用的清理工具
- 手机重度用户：社交截图、聊天图片、下载图片堆积，重点在快速清理垃圾图片
- 摄影爱好者：拍照量大，需要批量筛选保留好照片

## 核心流程

```
首页 ──→ [开始清理] ──→ 滑动浏览（一组N张） ──→ 确认删除页 ──→ 回到首页
  │
  └──→ [筛选后清理] ──→ 筛选页 ──→ 滑动浏览 ──→ 确认删除页 ──→ 回到首页
```

## 页面设计

### 1. 首页（仪表盘）

展示存储概览和清理成就，提供快速入口。

**布局元素：**
- App Logo / 名称
- 存储空间卡片：已用/总量进度条，照片和视频各占多少空间，进度条颜色随使用率变化（绿→黄→红）
- 清理成就卡片：累计已清理数量、累计释放空间（数据持久化在本地）
- 「开始清理」主按钮：页面中最大最醒目的元素，带轻微脉冲动画
- 照片/视频模式切换：两个并排卡片，显示各自总数量，选中态有高亮边框
- 「筛选后清理」次要入口：文字链接样式

**首次打开流程：**
- App 启动 → 相册权限请求 → 授权成功 → 首页数据加载 → 就绪
- 拒绝授权 → 引导页说明权限用途 → 跳转系统设置

**Limited Photos Access 处理（iOS 14+）：**
- 用户可能只授权部分照片的访问权限
- 首页显示提示横幅："你只授权了部分照片，点击管理权限"
- 点击横幅调用 `PHPhotoLibrary.shared().presentLimitedLibraryPicker()` 让用户扩大选择
- 筛选页仅展示可访问的相册和照片，数量标注"（已授权）"
- 存储空间卡片中照片/视频占用仅统计可访问的部分，标注"部分统计"
- 所有功能正常运作，仅作用于已授权的照片子集

### 2. 筛选页

选择范围后从符合条件的照片/视频中随机抽取清理。

**筛选维度：**

时间范围（单选）：
- 全部时间（默认）
- 1年前 / 2年前 / 3年前
- 自定义范围：日期选择器

相册（多选）：
- 列出所有用户相册，附带数量
- 包含系统智能相册（截屏、自拍、Live Photos 等）
- 默认"所有照片"

**筛选逻辑：**
- 时间和相册为 AND 关系
- 底部实时显示符合条件的数量
- 数量不足一组时提示"照片不足，将展示全部 N 张"
- 符合条件的照片全部浏览过时提示"这个范围都清理过了"

### 3. 滑动浏览页（核心页面）

全屏沉浸式浏览，纯手势操作。

**页面布局：**
- 照片/视频全屏展示
- 顶部半透明状态栏：返回按钮、已标记删除数（🗑×N）、进度（3/20）
- 底部半透明信息栏：拍摄日期、文件大小
- 底部进度条

**手势系统：**

| 手势 | 动作 | 视觉反馈 |
|------|------|----------|
| 上滑 ↑ | 保留，下一张 | 照片向上飞出，轻微绿色闪烁 |
| 左滑 ← | 标记删除，下一张 | 照片向左飞出，红色 × 动画 |
| 下滑 ↓ | 回看上一张 | 上一张从顶部滑入 |
| 右滑 → | 无操作 | 轻微弹回（防误触） |
| 单击 | 隐藏/显示 UI | 纯净模式切换 |
| 双指缩放 | 放大查看细节 | 标准缩放手势 |

**滑动反馈：**
- 照片跟随手指实时移动，有方向倾斜效果
- 滑动超过屏幕 1/3 时显示操作提示（"保留 ✓" 或 "删除 ×"）
- 未超过阈值松手：弹回原位
- 触发后：弹性动画飞出，下一张从对应方向滑入

**首次使用引导：**
- 3步手势动画教程（上滑=保留、左滑=删除、下滑=回看）
- 可跳过，仅显示一次

**边界情况：**
- 第一张下滑：弹性反馈，无操作
- 回看时标记状态：下滑回看上一张时，显示该张当前标记状态（如有红色删除标记）。用户可重新操作（上滑改为保留 / 左滑改为删除），新操作覆盖之前的标记
- 最后一张操作后：自动跳转确认删除页
- 中途退出：会话状态仅保留在内存中（进程存活期间有效）。App 被系统杀掉后会话丢失，用户需重新开始。不做磁盘持久化——清理会话是轻量操作，重新开始成本低

**视频模式差异：**
- 使用 `AVPlayer` + `AVPlayerLayer` 自定义播放器（非 `AVPlayerViewController`，以便手势共存）
- 进入视图后自动静音播放前 3 秒，随后循环播放这 3 秒
- 点击屏幕中央可暂停/继续播放
- 底部音量按钮可开启/关闭声音
- 可拖动进度条查看完整视频
- 文件大小更醒目地展示
- 缩略图叠加时长标签
- 手势操作与照片模式完全相同（手势识别器优先级高于播放控制区域外的触摸）

### 4. 确认删除页

浏览完一组后，统一确认删除标记的照片/视频。

**布局元素：**
- 顶部统计：已标记 N 张，预计释放 XX MB
- 逐张大图预览区：左右滑动查看每张标记的照片/视频，底部渐变蒙层显示日期和大小
- 左上角序号标签，右上角 × 撤回按钮
- 圆点指示器 + 底部横向缩略图导航条（选中项高亮边框）
- 视频缩略图叠加时长标签

**操作按钮：**
- 「确认删除 (N)」：红色主按钮
- 「再来一组」：放弃当前所有标记（不执行删除），开始全新的随机会话
- 「全部撤回」：清空所有标记，回到浏览页第一张重新浏览

**删除完成后：**
- 成功动画（照片缩小消散）
- 显示本次结果："已清理 N 张，释放 XX MB"
- 用户点击「回到首页」或「再来一组」继续（不自动跳转，让用户自己决定）

**特殊情况：**
- 全部保留（0 张标记）：显示"这组全部保留！"，提供「再来一组」

### 5. 设置页

**设置项：**
- 每组数量：10 / 20（默认）/ 30 / 50
- 手势引导：重置按钮，重新播放教程
- 清理记录：历史清理时间线（日期、数量、释放空间）
- 关于：版本号

## 技术架构

### 技术栈

| 层级 | 选型 | 说明 |
|------|------|------|
| UI 框架 | SwiftUI | iOS 17+ |
| 相册访问 | PhotoKit (Photos framework) | Apple 官方相册 API |
| 数据持久化 | SwiftData | 清理记录、用户设置 |
| 存储信息 | FileManager | 设备存储空间 |
| 动画 | SwiftUI Animation | 手势 + 过渡动画 |
| 架构模式 | MVVM | SwiftUI 标准模式 |

### 模块划分

```
App
├── Views/
│   ├── HomeView          — 首页仪表盘
│   ├── SwipeView         — 滑动浏览页
│   ├── ConfirmDeleteView — 确认删除页
│   ├── FilterView        — 筛选页
│   └── SettingsView      — 设置页
├── ViewModels/
│   ├── HomeViewModel
│   ├── SwipeViewModel
│   ├── ConfirmDeleteViewModel
│   └── FilterViewModel
├── Models/
│   ├── AssetItem         — 浏览会话中的资源
│   ├── CleanSession      — 清理会话
│   ├── CleanRecord       — 清理记录（持久化）
│   └── UserSettings      — 用户设置（持久化）
└── Services/
    ├── PhotoLibraryService  — 相册读写
    ├── StorageService       — 存储信息
    └── StatisticsService    — 清理统计
```

### 数据模型

```swift
// 当前浏览会话中的一个资源
struct AssetItem {
    let phAsset: PHAsset
    let localIdentifier: String  // PHAsset.localIdentifier，用于标识
    var markedForDeletion: Bool
    var fileSize: Int64          // 通过 PHAssetResource 获取
}

// 一次清理会话
struct CleanSession {
    let id: UUID
    let mode: CleanMode
    let filter: FilterCriteria?
    var assets: [AssetItem]
    var currentIndex: Int
}

enum CleanMode: String, Codable {
    case photo
    case video
}

// 筛选条件
struct FilterCriteria {
    var dateRange: DateRange?
    var albumIds: [String]?
}

// 时间范围
struct DateRange {
    let start: Date?
    let end: Date?
}

// 清理记录（持久化）
@Model
class CleanRecord {
    let date: Date
    let deletedCount: Int
    let freedSpace: Int64       // 字节数
    let mode: CleanMode
}

// 用户设置（持久化）
@Model
class UserSettings {
    var batchSize: Int = 20
    var hasSeenTutorial: Bool = false
}
```

### 关键流程

**相册权限：**
- 需要 `.readWrite` 权限
- 处理 `.authorized`、`.limited`、`.denied`、`.notDetermined` 四种状态
- iOS 14+ Limited Photos Access 需特殊处理
- Info.plist 配置 `NSPhotoLibraryUsageDescription`

**随机抽取：**
- PhotoLibraryService 获取所有符合条件的 PHAsset
- Fisher-Yates shuffle 随机打乱
- 取前 N 个构建 CleanSession

**执行删除：**
- 收集所有 `markedForDeletion = true` 的 PHAsset
- 调用 `PHPhotoLibrary.shared().performChanges` 删除
- iOS 系统会弹出强制确认弹窗（不可跳过）
- 实际流程：app 内确认 → 系统确认 → 移入"最近删除"
- 记录 CleanRecord，更新首页统计

### 系统要求

- iOS 17.0+
- iPhone 设备（MVP 不做 iPad 适配）

### 图片/视频加载策略

**照片加载：**
- 使用 `PHCachingImageManager` 进行预加载
- 预取窗口：当前照片前后各 3 张（共缓存 7 张）
- 目标尺寸：先加载屏幕尺寸的缩略图（`deliveryMode: .opportunistic`），再异步加载全分辨率
- 当用户滑动到新位置时，更新预取窗口：停止不再需要的缓存，开始新位置附近的缓存
- 内存警告时清空预取缓存，仅保留当前显示的图片

**视频加载：**
- 使用 `AVPlayer` + `AVPlayerLayer`，非 `AVPlayerViewController`
- 预创建下一个视频的 `AVPlayerItem`（仅预加载 1 个）
- 当前视频滑走后，复用 `AVPlayer` 切换到下一个 `AVPlayerItem`

**文件大小获取：**
- 通过 `PHAssetResource.assetResources(for: phAsset)` 获取资源列表
- 取主资源（`.photo` 或 `.video` 类型）的 `value(forKey: "fileSize")` 作为文件大小
- 对于 iCloud 优化存储的照片，报告的是完整资源大小（非本地缩略图大小），因为删除后系统会释放完整空间的占位
- 文件大小在构建 `CleanSession` 时批量获取并缓存到 `AssetItem.fileSize`

### 错误处理

**相册访问失败：**
- 权限被拒：显示引导页，提供跳转系统设置的按钮
- `PHAsset` fetch 返回 0 结果：提示"没有找到照片，试试调整筛选条件"

**删除失败：**
- `performChanges` 部分失败（某些资源已不存在）：提示"N 张已删除，M 张无法删除（可能已被其他应用移除）"，仅记录成功部分
- `performChanges` 完全失败：提示"删除失败，请重试"，保留标记状态不清空
- 用户在系统确认弹窗中点"取消"：回到确认删除页，标记状态保留

**iCloud 相关：**
- 如果照片仅存在于 iCloud（本地无缓存），图片加载时显示加载指示器
- 加载超时（10秒）：显示占位图 + "无法加载，可能需要网络连接"
- 用户仍可标记删除 iCloud-only 的照片

**内存警告：**
- 收到 `didReceiveMemoryWarning` 时清空 `PHCachingImageManager` 的预取缓存
- 仅保留当前显示的图片/视频

### App 生命周期

- 使用 SwiftUI 的 `scenePhase` 监听前后台切换
- 进入后台（`.background`）：暂停视频播放，停止图片预取
- 回到前台（`.active`）：恢复视频播放，重新启动预取
- 清理会话状态保存在内存中，App 进程存活期间有效
- App 被系统终止后会话丢失，这是预期行为

### 无障碍支持

**VoiceOver：**
- 滑动浏览页为每张照片提供 `accessibilityLabel`："{拍摄日期}的{照片/视频}，{文件大小}"
- 提供 VoiceOver 自定义操作（Custom Actions）替代手势：
  - "保留" → 等同于上滑
  - "删除" → 等同于左滑
  - "上一张" → 等同于下滑
- 确认删除页：每个缩略图标注"第N张，{日期}，点击撤回删除标记"

**Dynamic Type：**
- 所有文字使用系统动态字体
- 布局使用 SwiftUI 自适应布局，避免固定尺寸

**Reduce Motion：**
- 检查 `UIAccessibility.isReduceMotionEnabled`
- 开启时：滑动动画改为简单淡入淡出（无飞出+倾斜效果）
- 进度条和脉冲动画静态显示

### 导航架构

**导航方案：** 使用 `NavigationStack`（iOS 17+）+ 路径枚举

```swift
// 导航目标枚举
enum AppDestination: Hashable {
    case swipe(CleanMode)           // 滑动浏览页（照片/视频模式）
    case confirmDelete              // 确认删除页
    case filter                     // 筛选页
    case settings                   // 设置页
    case result(CleanResult)        // 清理结果页
}
```

**页面跳转路径图：**

```
HomeView (根视图)
    ├── .swipe(.photo)  ──→ SwipeView ──→ .confirmDelete ──→ ConfirmDeleteView
    │                                                            ├── .result ──→ ResultView
    │                                                            │     ├── popToRoot (回首页)
    │                                                            │     └── .swipe (再来一组)
    │                                                            └── .swipe (全部撤回/再来一组)
    ├── .swipe(.video)  ──→ (同上)
    ├── .filter         ──→ FilterView ──→ .swipe ──→ (同上)
    └── .settings       ──→ SettingsView
```

**实现要点：**
- `HomeView` 持有 `@State private var path = NavigationPath()`
- 使用 `.navigationDestination(for: AppDestination.self)` 注册目标视图
- 回到首页使用 `path.removeLast(path.count)` 清空导航栈
- 避免使用 `NavigationLink` 直接跳转，统一通过 `path.append()` 管理

### 状态管理

**架构原则：** 使用 iOS 17 的 `@Observable` 宏替代 `ObservableObject`

```
┌─────────────────────────────────────────────────┐
│  App 级别（@Environment 注入）                     │
│  ├── PhotoLibraryService  — 相册读写              │
│  ├── StorageService       — 存储信息              │
│  └── StatisticsService    — 清理统计              │
├─────────────────────────────────────────────────┤
│  页面级别（@State 管理）                           │
│  ├── HomeViewModel        — 首页数据              │
│  ├── SwipeViewModel       — 滑动状态 + 会话管理    │
│  ├── ConfirmDeleteViewModel — 标记管理            │
│  └── FilterViewModel      — 筛选条件              │
└─────────────────────────────────────────────────┘
```

**数据流向：**

```
Services (单例，App 生命周期)
    │
    ├── @Environment 注入到 View
    │
    ▼
ViewModel (@Observable，页面生命周期)
    │
    ├── @State var viewModel 在 View 中持有
    ├── 通过 Service 方法获取/修改数据
    │
    ▼
View (SwiftUI，声明式 UI)
    │
    └── 直接绑定 ViewModel 属性
```

**实现要点：**
- Services 使用 `@Observable` 宏，通过 `.environment()` 在 App 入口注入
- ViewModel 使用 `@Observable` 宏，通过 `@State` 在 View 中创建
- `CleanSession` 由 `SwipeViewModel` 持有，仅存内存
- `CleanRecord` 和 `UserSettings` 通过 SwiftData `@Query` 和 `ModelContext` 管理

### 设计系统

**语义颜色 Token：**

| Token 名 | 浅色模式 | 深色模式 | 用途 |
|-----------|----------|----------|------|
| `appBackground` | `.systemBackground` | `.systemBackground` | 页面背景 |
| `cardBackground` | `.secondarySystemBackground` | `.secondarySystemBackground` | 卡片背景 |
| `primaryText` | `.label` | `.label` | 主要文字 |
| `secondaryText` | `.secondaryLabel` | `.secondaryLabel` | 次要文字 |
| `success` | `#34C759` (系统绿) | `#30D158` | 保留操作反馈 |
| `destructive` | `#FF3B30` (系统红) | `#FF453A` | 删除操作/警告 |
| `warning` | `#FF9500` (系统橙) | `#FF9F0A` | 存储警告 |
| `accent` | `#43e97b`（清新薄荷） | `#43e97b` | 主操作按钮（详见 UI 设计规格） |

**字体系统：**

| 层级 | 系统样式 | 用途 |
|------|----------|------|
| 大标题 | `.largeTitle` | 首页数字统计 |
| 标题 | `.title2` | 页面标题 |
| 副标题 | `.headline` | 卡片标题 |
| 正文 | `.body` | 一般内容 |
| 说明 | `.caption` | 次要信息、底部栏 |

- 全部使用系统动态字体（`Font.system(.body)`），自动支持 Dynamic Type
- 不使用自定义字体（减小包体积 + 更好的系统一致性）

**间距系统：**

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4pt | 紧凑元素间距 |
| `sm` | 8pt | 元素内间距 |
| `md` | 16pt | 卡片内间距、列表行间距 |
| `lg` | 24pt | 区块间距 |
| `xl` | 32pt | 页面边距、大区块间距 |

**圆角与阴影：**

| 元素 | 圆角 | 阴影 |
|------|------|------|
| 卡片 | 16pt | 浅色：0.1 opacity, y:2, blur:8 |
| 按钮（主） | 14pt | 无 |
| 按钮（次） | 10pt | 无 |
| 缩略图 | 8pt | 无 |
| 底部安全区按钮 | Capsule | 无 |

### 触觉反馈

| 场景 | 反馈类型 | UIKit API |
|------|----------|-----------|
| 上滑达到阈值（保留） | Light Impact | `UIImpactFeedbackGenerator(style: .light)` |
| 左滑达到阈值（删除） | Medium Impact | `UIImpactFeedbackGenerator(style: .medium)` |
| 手势触发（松手后确认操作） | Selection | `UISelectionFeedbackGenerator()` |
| 删除成功 | Notification Success | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |
| 删除失败 | Notification Error | `UINotificationFeedbackGenerator().notificationOccurred(.error)` |
| 回看到第一张（边界） | Notification Warning | `UINotificationFeedbackGenerator().notificationOccurred(.warning)` |

**Reduce Motion 适配：**
- 检查 `UIAccessibility.isReduceMotionEnabled`
- 开启时：触觉反馈保留（触觉不受 Reduce Motion 影响）
- 仅视觉动画简化为淡入淡出

### 屏幕方向

- **锁定竖屏：** 仅支持 Portrait 方向
- 原因：全屏滑动浏览体验针对竖屏设计，横屏无额外价值

**Info.plist 配置：**
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

- Xcode 项目设置中 Device Orientation 仅勾选 Portrait

### App 图标与启动屏幕

**App 图标规格：**

| 尺寸 | 用途 |
|------|------|
| 1024×1024 | App Store |
| 180×180 | iPhone @3x |
| 120×120 | iPhone @2x |
| 60×60 | iPhone @1x (Spotlight) |

- 使用单一 1024×1024 资源，Xcode 15+ 自动生成所有尺寸
- 图标设计方向：简洁、辨识度高，包含滑动/清理的视觉隐喻
- 配置在 `Assets.xcassets/AppIcon.appiconset`

**启动屏幕：**
- 使用 `LaunchScreen.storyboard`（SwiftUI 不支持作为 Launch Screen）
- 内容：居中显示 App Logo，纯色背景
- 背景色与首页背景一致，确保无缝过渡
- 支持深色模式（使用系统语义色）
