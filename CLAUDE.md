# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PicSwipe** — iOS 原生照片/视频快速清理工具。用户通过沉浸式的全屏滑动体验（上滑保留、左滑删除）快速清理手机中不需要的照片和视频。

## Project Status

- ✅ 产品设计规格已完成：`docs/superpowers/specs/2026-03-19-picswipe-design.md`
- 🔄 PRD 文档编写中
- ⬜ 实施计划待编写
- ⬜ 代码开发未开始

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
├── App/                    — App entry point, lifecycle
├── Views/                  — SwiftUI views
│   ├── HomeView            — 首页仪表盘
│   ├── SwipeView           — 滑动浏览页（核心）
│   ├── ConfirmDeleteView   — 确认删除页
│   ├── FilterView          — 筛选页
│   └── SettingsView        — 设置页
├── ViewModels/             — View models (MVVM)
├── Models/                 — Data models (AssetItem, CleanSession, CleanRecord, UserSettings)
├── Services/               — Business logic
│   ├── PhotoLibraryService — 相册读写、随机抽取
│   ├── StorageService      — 设备存储信息
│   └── StatisticsService   — 清理统计
└── docs/
    └── superpowers/
        ├── specs/          — 设计规格文档
        └── plans/          — 实施计划
```

## Key Design Decisions

- **交互模式:** 纯手势操作（上滑=保留，左滑=删除，下滑=回看），无按钮
- **删除流程:** 标记 → 统一确认 → 系统最近删除（非永久删除）
- **会话状态:** 仅内存，不做磁盘持久化
- **照片/视频:** 分开为两个独立清理模式
- **每组数量:** 用户可设置（10/20/30/50），默认20

## Build & Run

> 尚未创建 Xcode 项目。项目创建后更新此处。

```bash
# TODO: Add build commands after Xcode project is created
# open PicSwipe.xcodeproj
# xcodebuild -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Testing

> 测试框架尚未配置。

```bash
# TODO: Add test commands
# xcodebuild test -scheme PicSwipe -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Language Preference

- 文档和注释使用**中文**
- 代码（变量名、函数名）使用**英文**
- Git commit messages 使用**英文**
