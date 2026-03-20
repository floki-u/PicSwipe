import SwiftUI
import SwiftData

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
                    storageCapsule
                    startCleaningCard
                    dataCardRow
                    bottomActions
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            vm.loadData(
                photoService: photoService,
                storageService: storageService,
                statsService: statsService,
                modelContext: modelContext
            )
        }
    }

    // MARK: - 品牌英雄区

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.15),
                    Color.brandSecondary.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.hero))

            // 装饰性辐射光晕
            RadialGradient(
                colors: [Color.brandPrimary.opacity(0.25), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 80
            )
            .frame(width: 160, height: 160)
            .offset(x: 20, y: -20)
            .blur(radius: 8)

            // 主内容
            VStack(spacing: Spacing.sm) {
                Text("🌿")
                    .font(.system(size: 56))
                Text("PicSwipe")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("滑一滑，轻松释放空间")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
    }

    // MARK: - 存储胶囊

    private var storageCapsule: some View {
        HStack(spacing: Spacing.md) {
            storageLabel
            storageMiniBar
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private var storageLabel: some View {
        let used = vm.storageInfo.usedSpace
        let total = vm.storageInfo.totalSpace
        return Text("\(formatFileSize(used)) / \(formatFileSize(total))")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .lineLimit(1)
    }

    private var storageMiniBar: some View {
        let pct = vm.storageInfo.usagePercentage
        let barColor: Color = {
            switch pct {
            case ..<0.7: return .brandPrimary
            case 0.7..<0.9:
                // 线性插值：green → yellow
                let t = (pct - 0.7) / 0.2
                return Color(
                    red: 0.263 + (0.957 - 0.263) * t,
                    green: 0.914 + (0.773 - 0.914) * t,
                    blue: 0.482 + (0.259 - 0.482) * t
                )
            default: return .warningYellow
            }
        }()

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width * min(CGFloat(pct), 1.0))
            }
        }
        .frame(height: 6)
    }

    // MARK: - 开始清理卡片

    private var startCleaningCard: some View {
        Button {
            path.append(AppDestination.swipe(vm.selectedMode))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text("✨")
                            .font(.title3)
                        Text("开始清理")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                    }
                    Text("随机抽取 \(vm.batchSize) 张\(vm.selectedMode == .photo ? "照片" : "视频")")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.65))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.8))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
            .background(LinearGradient.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 三联数据卡片

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
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 底部操作区

    private var bottomActions: some View {
        HStack {
            // 筛选后清理（V1.1 占位）
            Button {
                // V1.1 预留
            } label: {
                Text("筛选后清理 →")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
            }
            .disabled(true)

            Spacer()

            // 设置入口
            Button {
                path.append(AppDestination.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.xs)
    }
}
