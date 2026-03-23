# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PicS**（代码名 PicSwipe）— iOS 原生照片/视频快速清理工具。用户通过沉浸式的全屏滑动体验（上滑保留、左滑删除）快速清理手机中不需要的照片和视频。

## Project Status

- ✅ 产品设计规格已完成：`docs/superpowers/specs/2026-03-19-picswipe-design.md`
- ✅ PRD 文档已完成：`docs/PRD.md`
- ✅ UI 设计规格（V1.0 初稿）：`docs/superpowers/specs/2026-03-20-picswipe-ui-design.md`
- ✅ UI 设计规格（V1.1 现行版）：`docs/superpowers/specs/2026-03-20-pics-v1.1-ui-design.md`
- ✅ MVP V1.0 实施计划：`docs/superpowers/plans/2026-03-20-picswipe-mvp.md`
- ✅ MVP V1.0 代码开发已完成
- ✅ V1.1 细节打磨与体验优化已完成：`docs/superpowers/specs/2026-03-20-pics-v1.1-implementation.md`
- ✅ 里程碑追踪：`docs/superpowers/plans/2026-03-20-pics-milestones.md`
- ✅ 待优化与未来规划：`docs/superpowers/plans/2026-03-20-pics-backlog.md`
- ⬜ V1.2 筛选与增强
- ⬜ V2.0 智能清理

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI (iOS 17+)
- **Photo Access:** PhotoKit (Photos framework)
- **Persistence:** SwiftData
- **Architecture:** MVVM
- **Target:** iPhone only, iOS 17.0+

## Project Structure

```
PicSwipe/
├── Assets.xcassets/        — 应用图标
├── App/                    — App entry point, lifecycle
├── Views/                  — SwiftUI views
│   ├── HomeView            — 首页仪表盘
│   ├── SwipeView           — 滑动浏览页（核心）
│   ├── SwipeCardView       — 单张卡片（照片/视频）
│   ├── VideoPlayerView     — 增强视频播放器
│   ├── ConfirmDeleteView   — 确认删除页（照片/视频双布局）
│   ├── FullScreenPhotoView — 全屏照片查看器
│   ├── ResultView          — 结果页（照片绿/视频红）
│   ├── FilterView          — 筛选页（V1.2）
│   └── SettingsView        — 设置页
├── ViewModels/             — View models (MVVM)
├── Models/                 — Data models (AssetItem, CleanSession, CleanRecord, UserSettings)
├── Services/               — Business logic
│   ├── PhotoLibraryService — 相册读写、随机抽取（后台线程）
│   ├── StorageService      — 设备存储信息
│   ├── StatisticsService   — 清理统计
│   └── HapticService       — 触觉反馈
└── docs/
    ├── PRD.md              — 产品需求文档
    └── superpowers/
        ├── specs/          — 设计规格文档
        │   ├── 2026-03-19-picswipe-design.md      — 技术设计规格
        │   ├── 2026-03-20-picswipe-ui-design.md   — UI 设计规格（V1.0 初稿）
        │   ├── 2026-03-20-pics-v1.1-ui-design.md  — UI 设计规格（V1.1 现行版）
        │   └── 2026-03-20-pics-v1.1-implementation.md — V1.1 实施记录
        └── plans/          — 实施计划
            ├── 2026-03-20-picswipe-mvp.md          — V1.0 MVP 计划
            ├── 2026-03-20-pics-milestones.md       — 里程碑追踪
            └── 2026-03-20-pics-backlog.md          — 待优化与未来规划
```

## Key Design Decisions

- **交互模式:** 纯手势操作（上滑=保留，左滑=删除，下滑=回看），无按钮
- **删除流程:** 标记 → 统一确认 → 系统最近删除（非永久删除）
- **会话状态:** 仅内存，不做磁盘持久化
- **照片/视频:** 分开为两个独立清理模式
- **每组数量:** 用户可设置（10/20/30/50），默认20

## Build & Run

```bash
# 打开 Xcode 项目（项目创建后可用）
open PicSwipe.xcodeproj

# 命令行构建
xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16'

# 命令行运行模拟器
xcrun simctl boot "iPhone 16" && xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Language Preference

- 文档和注释使用**中文**
- 代码（变量名、函数名）使用**英文**
- Git commit messages 使用**英文**

## Development Environment

### 系统要求

| 项目 | 最低版本 |
|------|----------|
| macOS | 14.0 (Sonoma)+ |
| Xcode | 15.1+ |
| iOS SDK | 17.0 |
| Swift | 5.9+ |

### 模拟器测试设备

| 设备 | 屏幕尺寸 | 用途 |
|------|----------|------|
| iPhone SE (3rd) | 4.7" | 最小屏幕适配 |
| iPhone 16 | 6.1" | 主要测试设备 |
| iPhone 16 Pro Max | 6.9" | 最大屏幕适配 |

## Git Workflow

### 分支策略

```
main ← develop ← feature/xxx
                ← bugfix/xxx
                ← docs/xxx
```

- `main`：稳定发布版本，仅通过 PR 合入
- `develop`：开发集成分支，功能完成后合入
- `feature/xxx`：功能开发分支
- `bugfix/xxx`：Bug 修复分支
- `docs/xxx`：文档更新分支

### Commit 规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Type 列表：**

| Type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `refactor` | 代码重构（不改变行为） |
| `test` | 测试相关 |
| `chore` | 构建/工具/配置 |
| `style` | 代码格式（不影响逻辑） |
| `perf` | 性能优化 |

**Scope 列表：**

| Scope | 对应模块 |
|-------|----------|
| `home` | 首页仪表盘 |
| `swipe` | 滑动浏览页 |
| `confirm` | 确认删除页 |
| `filter` | 筛选页 |
| `settings` | 设置页 |
| `photo-service` | PhotoLibraryService |
| `storage-service` | StorageService |
| `stats-service` | StatisticsService |
| `models` | 数据模型 |
| `app` | App 入口/生命周期 |

**示例：**
```
feat(swipe): add drag gesture with directional tilt effect
fix(photo-service): handle nil fileSize for iCloud-only assets
docs(prd): add competitive analysis section
```

## Code Style Guide

### 命名约定

| 类型 | 规则 | 示例 |
|------|------|------|
| 类型（struct/class/enum） | PascalCase | `AssetItem`, `CleanSession` |
| 协议 | PascalCase + 描述性后缀 | `PhotoLibraryProviding` |
| 变量/属性 | camelCase | `currentIndex`, `markedForDeletion` |
| 函数/方法 | camelCase + 动词开头 | `fetchAssets()`, `markForDeletion()` |
| 常量 | camelCase | `maxBatchSize` |
| 枚举 case | camelCase | `case photo`, `case video` |

### 布尔变量命名

- 使用 `is`/`has`/`should`/`can` 前缀
- 示例：`isLoading`, `hasSeenTutorial`, `shouldShowBanner`, `canDelete`

### 文档注释

```swift
/// 从相册中随机抽取一组照片
/// - Parameters:
///   - mode: 清理模式（照片/视频）
///   - count: 抽取数量
///   - filter: 可选筛选条件
/// - Returns: 构建好的清理会话
/// - Throws: `PhotoError.noAssets` 如果没有符合条件的照片
func fetchRandomAssets(mode: CleanMode, count: Int, filter: FilterCriteria?) async throws -> CleanSession
```

### SwiftLint 配置要点

```yaml
# .swiftlint.yml
opt_in_rules:
  - empty_count
  - closure_spacing
  - force_unwrapping
  - implicitly_unwrapped_optional

disabled_rules:
  - trailing_whitespace   # Xcode 自动处理

line_length:
  warning: 120
  error: 150

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 800
```

### 其他规范

- 每个文件只包含一个主要类型定义
- 使用 `// MARK: -` 组织代码区块
- 优先使用 `guard` 提前返回，减少嵌套
- 避免 Force Unwrap（`!`），使用 `guard let` 或 `if let`
- View 文件中分离 UI 子组件为 `private` 计算属性或私有 View

## Testing

### 测试框架

- 单元测试：XCTest
- UI 测试：XCUITest
- 测试目标：`PicSwipeTests`（单元）、`PicSwipeUITests`（UI）

### 覆盖率目标

| 层级 | 目标覆盖率 |
|------|-----------|
| Services | > 80% |
| ViewModels | > 70% |
| Models | > 90% |
| Views | UI 测试覆盖核心流程 |

### 测试命名规范

```swift
// 格式：test_<被测方法>_<场景>_<预期结果>
func test_fetchRandomAssets_withEmptyLibrary_throwsNoAssetsError()
func test_markForDeletion_togglesFlag_andUpdatesCount()
```

### 运行命令

```bash
# 运行全部单元测试
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests

# 运行全部 UI 测试
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeUITests

# 运行特定测试文件
xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PicSwipeTests/PhotoLibraryServiceTests
```
