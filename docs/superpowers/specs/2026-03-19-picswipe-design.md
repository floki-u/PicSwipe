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
- 最后一张操作后：自动跳转确认删除页
- 中途退出：标记状态保存，下次可继续或重新开始

**视频模式差异：**
- 自动播放前 3 秒预览（静音）
- 点击可暂停/播放，可拖动进度条
- 点击可开启声音
- 文件大小更醒目地展示
- 缩略图叠加时长标签
- 手势操作与照片模式完全相同

### 4. 确认删除页

浏览完一组后，统一确认删除标记的照片/视频。

**布局元素：**
- 顶部统计：已标记 N 张，预计释放 XX MB
- 网格缩略图展示所有标记的照片/视频
- 每张右上角有 × 按钮可撤回标记
- 点击缩略图可全屏预览
- 视频缩略图叠加时长标签

**操作按钮：**
- 「确认删除 (N)」：红色主按钮
- 「再来一组」：不删除当前，开始下一组
- 「全部撤回」：清空所有标记，回到浏览页

**删除完成后：**
- 成功动画（照片缩小消散）
- 显示本次结果："已清理 N 张，释放 XX MB"
- 2秒后自动回首页，或点击「再来一组」继续

**特殊情况：**
- 全部保留（0 张标记）：显示"这组全部保留！"，提供「再来一组」
- 全部删除（20 张都标记）：额外二次确认"确定全部删除吗？"

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
    var markedForDeletion: Bool
}

// 一次清理会话
struct CleanSession {
    let id: UUID
    let mode: CleanMode
    let filter: FilterCriteria?
    var assets: [AssetItem]
    var currentIndex: Int
}

enum CleanMode {
    case photo
    case video
}

// 筛选条件
struct FilterCriteria {
    var dateRange: DateRange?
    var albumIds: [String]?
}

// 清理记录（持久化）
@Model
class CleanRecord {
    let date: Date
    let deletedCount: Int
    let freedSpace: Int64
    let mode: String
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
