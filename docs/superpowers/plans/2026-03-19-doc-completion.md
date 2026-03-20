# PicSwipe 文档完善计划 — 执行记录

> 日期：2026-03-19
> 状态：✅ 全部完成（未提交 Git）

---

## 执行状态总览

| Task | 描述 | 状态 | 修改文件 |
|------|------|------|----------|
| Task 1 | 修复 PRD 与 Spec 不一致 | ✅ 完成 | `docs/PRD.md`, `docs/superpowers/specs/2026-03-19-picswipe-design.md` |
| Task 2 | 补充 PRD 缺失章节 | ✅ 完成 | `docs/PRD.md` |
| Task 3 | 补充技术 Spec | ✅ 完成 | `docs/superpowers/specs/2026-03-19-picswipe-design.md` |
| Task 4 | 完善 CLAUDE.md | ✅ 完成 | `CLAUDE.md` |
| Task 5 | Git 提交 | ⏭️ 跳过 | 用户要求暂不提交 |

---

## Task 1 详细记录：修复不一致

### 1.1 S-04 回看标记状态
- **PRD** S-04 更新为：下滑回看显示当前标记状态，可重新操作覆盖
- **Spec** 滑动浏览页边界情况新增同样说明

### 1.2 F-17 Limited Access 移至 MVP
- **PRD** F-17 从 V1.1 P2 → V1.0 MVP P1
- **PRD** §14 版本规划：V1.0 范围加入 F-17，V1.1 范围移除 F-17

### 1.3 删除 C-10
- **PRD** 删除 C-10 条目（全部删除二次确认）
- **Spec** 确认删除页特殊情况删除对应描述

---

## Task 2 详细记录：PRD 新增章节

章节编号因插入而重排，以下为最终编号：

| 新章节 | 最终编号 | 关键内容 |
|--------|----------|----------|
| 竞品分析 | §3 | 5 个竞品对比 + 差异化定位表 |
| Onboarding 流程 | §5.3 | 完整流程图（欢迎→权限→教程→首次清理） |
| 边界情况与异常处理 | §8 | 11 个场景的处理方式 |
| 本地化策略 | §9 | zh-Hans + en，Strings Catalog 方案 |
| 隐私政策与合规 | §10 | Info.plist 描述 + 审核注意事项 |
| App Store 策略 | §11 | 元数据 + 5 张截图策略 + 描述方向 |
| 版本间数据迁移 | §12 | SwiftData VersionedSchema + V1.0→V1.1 迁移 |

### PRD 最终章节结构

```
§1  项目背景
§2  用户画像
§3  竞品分析 ← 新增
§4  功能清单与优先级（原§3）
§5  核心用户流程（原§4）
    §5.3 Onboarding 流程 ← 新增
§6  页面详细需求（原§5）
§7  非功能需求（原§6）
§8  边界情况与异常处理 ← 新增
§9  本地化策略 ← 新增
§10 隐私政策与合规 ← 新增
§11 App Store 策略 ← 新增
§12 版本间数据迁移 ← 新增
§13 技术方案概要（原§7）
§14 版本规划（原§8）
§15 开放问题（原§9）
§16 附录（原§10）
```

---

## Task 3 详细记录：Spec 新增章节

| 新章节 | 关键内容 |
|--------|----------|
| 导航架构 | NavigationStack + AppDestination 枚举 + 跳转路径图 |
| 状态管理 | @Observable + @Environment 注入 Services + 数据流向图 |
| 设计系统 | 8 个语义颜色 Token + 5 级字体 + 5 级间距 + 圆角阴影规范 |
| 触觉反馈 | 6 个场景的触觉类型 + Reduce Motion 适配 |
| 屏幕方向 | Portrait 锁定 + Info.plist 配置 |
| App 图标与启动屏幕 | 图标尺寸规格 + LaunchScreen.storyboard 方案 |

---

## Task 4 详细记录：CLAUDE.md 新增内容

| 新章节 | 关键内容 |
|--------|----------|
| Development Environment | macOS 14+, Xcode 15.1+, iOS 17.0 SDK, 3 台模拟器 |
| Git Workflow | main←develop←feature 分支策略 |
| Commit 规范 | Conventional Commits + 8 个 type + 10 个 scope |
| Code Style Guide | 命名约定 + 布尔前缀 + 文档注释 + SwiftLint 配置 |
| Testing | XCTest + 覆盖率目标（Services>80%, VM>70%）+ 运行命令 |
| Build & Run | 更新为实际构建命令（替换 TODO 占位符） |
| Project Status | PRD 标记为 ✅ 已完成 |

---

## 验证清单

- [x] PRD 与 Spec 无矛盾点
- [x] PRD 包含：竞品分析、Onboarding、边界情况、本地化、隐私政策、ASO、数据迁移
- [x] Spec 包含：导航架构、状态管理、设计系统、触觉反馈、屏幕方向、App 图标
- [x] CLAUDE.md 包含：Git 规范、代码风格、环境要求、测试策略
- [x] 所有文档使用中文（代码示例使用英文）

---

## 待办事项

- [ ] Git 提交（用户要求暂缓）
- [ ] 编写实施计划（下一阶段）
- [ ] 创建 Xcode 项目（开发阶段）
