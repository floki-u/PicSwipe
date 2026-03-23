// PicSwipe/Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData
import Photos

/// 设置页 — 像素 RPG 卡片式布局
struct SettingsView: View {
    @Binding var path: NavigationPath

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var userSettings: UserSettings?
    @State private var totalDeleted: Int = 0
    @State private var totalFreed: Int64 = 0
    @State private var showPrivacyPolicy: Bool = false

    private let batchOptions = [10, 20, 30, 50]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    // 页面标题
                    Text("SETTINGS")
                        .font(.pixel(14))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.xs)

                    brandCard

                    // GENERAL 分组
                    sectionLabel("GENERAL")
                    batchSizeCard

                    // STATS 分组
                    sectionLabel("STATS")
                    historyCard

                    // ABOUT 分组
                    sectionLabel("ABOUT")
                    otherCard
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.startLocation.x < 60 && value.translation.width > 80 {
                        path.removeLast()
                    }
                }
        )
        .sheet(isPresented: $showPrivacyPolicy) {
            privacyPolicySheet
        }
        .onAppear {
            loadData()
        }
    }

    /// 像素标签分组标题
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.pixel(8))
            .foregroundStyle(Color.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xs)
    }

    // MARK: - 品牌卡片

    private var brandCard: some View {
        DungeonCard {
            HStack(spacing: Spacing.md) {
                // 应用图标
                ZStack {
                    Color.brandPrimary.opacity(0.15)
                    Text("⚔️")
                        .font(.title)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("PicS")
                        .font(.pixel(12))
                        .foregroundStyle(Color.brandPrimary)

                    Text("V1.2.0 · Dungeon Edition")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    permissionBadge
                }

                Spacer()
            }
        }
    }

    private var permissionBadge: some View {
        let status = photoService.authorizationStatus
        let (text, color): (String, Color) = {
            switch status {
            case .authorized:
                return ("相册：已授权", Color.brandPrimary)
            case .limited:
                return ("相册：部分授权", Color.warningYellow)
            case .denied, .restricted:
                return ("相册：未授权", Color.destructiveRed)
            default:
                return ("相册：未确定", Color.textSecondary)
            }
        }()

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }

    // MARK: - 每组数量卡片

    private var batchSizeCard: some View {
        DungeonCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("每组数量")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                HStack(spacing: Spacing.sm) {
                    ForEach(batchOptions, id: \.self) { size in
                        batchSizeButton(size)
                    }
                }

                Text("每次清理会随机抽取这么多张照片")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private func batchSizeButton(_ size: Int) -> some View {
        let isSelected = userSettings?.batchSize == size

        return Button {
            selectBatchSize(size)
        } label: {
            Text("\(size)")
                .font(.pixel(9))
                .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? Color.brandPrimary.opacity(0.1)
                        : Color.white.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.chip))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.chip)
                        .stroke(
                            isSelected ? Color.brandPrimary : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
    }

    // MARK: - 清理历史卡片

    private var historyCard: some View {
        DungeonCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("清理历史")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Spacer()
                }

                HStack(spacing: 0) {
                    // 删除张数
                    VStack(spacing: 4) {
                        Text("\(totalDeleted)")
                            .font(.pixel(14))
                            .foregroundStyle(Color.brandPrimary)
                        Text("已删除张数")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 36)

                    // 释放空间
                    VStack(spacing: 4) {
                        Text(formatFileSize(totalFreed))
                            .font(.pixel(10))
                            .foregroundStyle(Color.brandPrimary)
                        Text("已释放空间")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - 其他设置卡片

    private var otherCard: some View {
        DungeonCard {
            VStack(spacing: 0) {
                settingsRow(emoji: "👆", title: "重播手势教程") {
                    replayTutorial()
                }

                divider

                settingsRow(emoji: "🔒", title: "相册权限") {
                    openSystemSettings()
                }

                divider

                settingsRow(emoji: "⚔️", title: "隐私政策") {
                    showPrivacyPolicy = true
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, -Spacing.md)
    }

    private func settingsRow(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(emoji)
                    .font(.body)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textMuted)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
    }

    // MARK: - 隐私政策 Sheet

    private var privacyPolicySheet: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("PicS 尊重您的隐私。以下是我们的隐私承诺：")
                            .font(.body)
                            .foregroundStyle(.white)

                        privacyItem(
                            icon: "shield.checkered",
                            title: "纯本地运行",
                            description: "所有操作均在您的设备上完成，照片不会上传到任何服务器。"
                        )

                        privacyItem(
                            icon: "antenna.radiowaves.left.and.right.slash",
                            title: "无网络请求",
                            description: "PicS 不需要网络连接，不会发送任何数据到外部。"
                        )

                        privacyItem(
                            icon: "person.crop.circle.badge.xmark",
                            title: "不收集个人信息",
                            description: "我们不收集、不存储、不分享您的任何个人信息或使用数据。"
                        )

                        privacyItem(
                            icon: "photo.on.rectangle",
                            title: "相册权限",
                            description: "仅用于读取和删除您选择清理的照片/视频。删除操作会先移至系统「最近删除」，30天内可恢复。"
                        )

                        privacyItem(
                            icon: "internaldrive",
                            title: "本地统计",
                            description: "清理历史记录仅保存在您的设备上，卸载应用后自动清除。"
                        )
                    }
                    .padding(.horizontal, Spacing.pagePadding)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showPrivacyPolicy = false
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    private func privacyItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 数据加载

    private func loadData() {
        userSettings = statsService.getSettings(in: modelContext)
        totalDeleted = statsService.totalDeletedCount(in: modelContext)
        totalFreed = statsService.totalFreedSpace(in: modelContext)
    }

    // MARK: - 操作

    private func selectBatchSize(_ size: Int) {
        guard let settings = userSettings else { return }
        settings.batchSize = size
        try? modelContext.save()
    }

    /// 重播手势教程：重置标记并返回首页触发 onboarding
    private func replayTutorial() {
        userSettings?.hasSeenTutorial = false
        try? modelContext.save()
        path = NavigationPath()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
