import SwiftUI
import SwiftData
import UIKit

// MARK: - HomeView

struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StorageService.self) private var storageService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var vm = HomeViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.md) {
                    heroSection
                    limitedAccessBanner
                    hpBarSection
                    startCleaningCard
                    quickFilterSection
                    dataCardRow
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await vm.loadData(
                photoService: photoService,
                storageService: storageService,
                statsService: statsService,
                modelContext: modelContext
            )
        }
    }

    // MARK: - 品牌英雄区（像素风格）

    private var heroSection: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.12),
                    Color.brandSecondary.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.hero))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.hero)
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
            )

            // 主内容
            VStack(spacing: Spacing.sm) {
                Text("⚔️")
                    .font(.system(size: 48))

                Text("PicS")
                    .font(.pixel(20))
                    .foregroundStyle(Color.brandPrimary)
                    .shadow(color: Color.brandPrimary.opacity(0.5), radius: 6, y: 2)

                // 像素星星装饰行
                Text("✦ ✦ ✦ ✦ ✦")
                    .font(.pixel(6))
                    .foregroundStyle(Color.warningYellow.opacity(0.6))

                Text("⚔️ 相册清理 · 地牢探索")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
    }

    // MARK: - Limited Access 横幅

    @ViewBuilder
    private var limitedAccessBanner: some View {
        if photoService.isLimited {
            Button(action: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    photoService.presentLimitedLibraryPicker(from: rootVC)
                }
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.warningYellow)
                    Text("你只授权了部分照片，点击管理权限")
                        .font(.caption)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.warningYellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.chip))
            }
        }
    }

    // MARK: - HP BAR 存储区

    private var hpBarSection: some View {
        DungeonCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("HP BAR")
                        .font(.pixel(8))
                        .foregroundStyle(Color.brandPrimary)
                    Spacer()
                    Text("\(formatFileSize(vm.storageInfo.usedSpace)) / \(formatFileSize(vm.storageInfo.totalSpace))")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .monospacedDigit()
                }

                HPBar(usagePercent: vm.storageInfo.usagePercentage)

                let freeSpace = vm.storageInfo.totalSpace - vm.storageInfo.usedSpace
                Text("剩余 \(formatFileSize(freeSpace)) 可用")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - 开始清理卡片（像素边框风格）

    private var startCleaningCard: some View {
        Button {
            path.append(AppDestination.swipe(vm.selectedMode))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("▶ START")
                        .font(.pixel(12))
                        .foregroundStyle(Color.brandPrimary)
                    Text("随机抽取 \(vm.batchSize) 张\(vm.selectedMode == .photo ? "照片" : "视频")")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.8))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
            .background(Color.brandPrimary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brandPrimary, lineWidth: 1.5)
            )
            .shadow(color: Color.brandPrimary.opacity(0.2), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 三联数据卡片（边框式）

    private var dataCardRow: some View {
        HStack(spacing: Spacing.sm) {
            modeCard(
                emoji: "📷",
                label: "照片",
                value: "\(vm.photoCount)",
                mode: .photo
            )
            modeCard(
                emoji: "🎬",
                label: "视频",
                value: "\(vm.videoCount)",
                mode: .video
            )
            statsCard(
                emoji: "🧹",
                label: "已释放",
                value: formatFileSize(vm.totalFreedSpace)
            )
            // 设置入口卡片
            Button {
                path.append(AppDestination.settings)
            } label: {
                dataCardContent(emoji: "⚙", label: "设置", value: "")
            }
            .buttonStyle(.plain)
        }
    }

    /// 可点击的模式切换卡片（照片 / 视频）
    private func modeCard(emoji: String, label: String, value: String, mode: CleanMode) -> some View {
        let isSelected = vm.selectedMode == mode
        return Button {
            vm.selectedMode = mode
        } label: {
            dataCardContent(emoji: emoji, label: label, value: value)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected ? Color.brandPrimary : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    /// 纯展示统计卡片
    private func statsCard(emoji: String, label: String, value: String) -> some View {
        dataCardContent(emoji: emoji, label: label, value: value)
    }

    private func dataCardContent(emoji: String, label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(emoji)
                .font(.title2)
            // 固定高度占位，确保所有卡片对齐
            Text(value.isEmpty ? " " : value)
                .font(.pixel(9))
                .foregroundStyle(value.isEmpty ? .clear : Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(height: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.cardGlowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - 快捷筛选区

    private var quickFilterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("快捷筛选")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // 截图标签
                    if vm.screenshotCount > 0 {
                        quickFilterChip(
                            emoji: "📷",
                            label: "截图",
                            badge: "\(vm.screenshotCount)"
                        ) {
                            var filter = FilterCriteria()
                            filter.screenshotsOnly = true
                            path.append(AppDestination.swipeWithFilter(.photo, filter))
                        }
                    }

                    // 大文件标签
                    if vm.largeFileCount > 0 {
                        quickFilterChip(
                            emoji: "📦",
                            label: "大文件",
                            badge: ">10MB"
                        ) {
                            var filter = FilterCriteria()
                            filter.largeFilesOnly = true
                            filter.sortBySize = true
                            path.append(AppDestination.swipeWithFilter(vm.selectedMode, filter))
                        }
                    }
                }
            }

            // 更多筛选条件链接
            Button {
                path.append(AppDestination.filter(vm.selectedMode))
            } label: {
                Text("更多筛选条件 ›")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private func quickFilterChip(emoji: String, label: String, badge: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                Text(badge)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.fillTertiary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cardGlowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
    }
}
