# PicS — 里程碑追踪

> 最后更新：2026-03-20

---

## 版本路线图

```
V1.0 MVP ──────── V1.1 打磨 ──────── V1.2 筛选 ──────── V2.0 智能
  ✅ 完成           ✅ 完成           ⬜ 计划中          ⬜ 规划中
 2026-03-20       2026-03-20
```

---

## V1.0 MVP — ✅ 已完成（2026-03-20）

| # | 里程碑 | 状态 | 说明 |
|---|--------|------|------|
| 1 | 项目初始化 | ✅ | Xcode 项目、SwiftData schema、设计系统 |
| 2 | 数据层 | ✅ | Models (AssetItem/CleanSession/CleanRecord/UserSettings) |
| 3 | 服务层 | ✅ | PhotoLibraryService/StorageService/StatisticsService/HapticService |
| 4 | 引导流程 | ✅ | WelcomeView → PermissionView → TutorialView |
| 5 | 首页仪表盘 | ✅ | HomeView（存储胶囊、数据卡片、开始清理） |
| 6 | 滑动浏览页 | ✅ | SwipeView + SwipeCardView（手势、动画、Live Photo） |
| 7 | 确认删除页 | ✅ | ConfirmDeleteView（预览、撤回、批量删除） |
| 8 | 结果页 | ✅ | ResultView（成功动画、统计数据） |
| 9 | 设置页 | ✅ | SettingsView（批量大小、历史、隐私政策） |
| 10 | 单元测试 | ✅ | 8 个测试文件覆盖 Models/Services/ViewModels |

---

## V1.1 细节打磨 — ✅ 已完成（2026-03-20）

| # | 里程碑 | 状态 | 说明 |
|---|--------|------|------|
| 1 | 品牌改名 PicS | ✅ | Info.plist/WelcomeView/HomeView/SettingsView |
| 2 | 启动优化 | ✅ | `.task` 替代 `.onAppear`，动画加速，转场优化 |
| 3 | 确认删除页增强 | ✅ | 全屏查看器、撤回胶囊按钮 |
| 4 | 照片滑动大改 | ✅ | 边缘渐变光晕、速度检测、自然飞出、触觉防抖 |
| 5 | 视频播放增强 | ✅ | 进度条、有声播放、暂停、2x 加速 |
| 6 | 视频交互独立化 | ✅ | 上下滑动、右侧浮动按钮、删除自动跳下一个 |
| 7 | 照片/视频独立 UI | ✅ | 确认删除页双布局、结果页双配色 |
| 8 | 应用图标 | ✅ | 品牌渐变圆 + S 字标 |
| 9 | 运行时优化 | ✅ | PhotoKit 后台线程、图片解码容错、动画时序修复 |
| 10 | 设置页优化 | ✅ | inline 标题、仅图标返回、左滑返回 |
| 11 | "再来一组" 行为 | ✅ | 直接开新清理会话而非回首页 |

---

## V1.2 筛选与增强 — ⬜ 计划中

| # | 里程碑 | 状态 | 说明 |
|---|--------|------|------|
| 1 | 筛选页 FilterView | ⬜ | 按日期范围、相册筛选后清理 |
| 2 | 截图自动识别 | ⬜ | 自动检测截图类型批量清理 |
| 3 | 重复照片检测 | ⬜ | 基于 perceptual hash 检测相似照片 |
| 4 | 大文件优先 | ⬜ | 按文件大小排序，优先清理大文件 |
| 5 | iCloud 照片处理 | ⬜ | 优雅处理 iCloud-only 资源 |
| 6 | Widget 支持 | ⬜ | 桌面小组件显示存储状态 |
| 7 | 批量操作增强 | ⬜ | 多选模式批量标记 |

---

## V2.0 智能清理 — ⬜ 规划中

| # | 里程碑 | 状态 | 说明 |
|---|--------|------|------|
| 1 | Core ML 模糊检测 | ⬜ | 自动识别模糊/低质量照片 |
| 2 | 智能分组 | ⬜ | 按场景/时间自动聚类 |
| 3 | 清理建议 | ⬜ | AI 推荐可删除的照片 |
| 4 | iPad 适配 | ⬜ | 分屏/多列布局 |
| 5 | 统计仪表盘 | ⬜ | 清理趋势图、时间线 |

---

## 技术债务清单

| 编号 | 问题 | 影响 | 优先级 | 建议方案 |
|------|------|------|--------|---------|
| TD-1 | 设置页 swipe-back 为自定义 DragGesture | 手感不如系统 | P3 | 用 UINavigationController delegate |
| TD-2 | VideoPlayerManager 用 Combine Subject 传递数据 | 与 @Observable 不一致 | P3 | 迁移到 AsyncStream 或纯 @Observable |
| TD-3 | ConfirmDeleteView 563 行过长 | 可读性 | P2 | 拆分为子 View 组件 |
| TD-4 | SwipeView 474 行过长 | 可读性 | P2 | 提取手势处理到独立文件 |
| TD-5 | 无 UI 测试覆盖 V1.1 新功能 | 回归风险 | P2 | 补充 XCUITest |
| TD-6 | 缺少 SwipeViewModel 视频模式测试 | 回归风险 | P1 | 补充 advanceToNext/markDeleteAndAdvance 测试 |
