// PicSwipe/Views/Swipe/SwipeView.swift
import SwiftUI
import SwiftData

/// 滑动浏览页 — 核心交互页面
/// 上滑保留、左滑删除、下滑回看、点击切换纯净模式
struct SwipeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let mode: CleanMode

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm = SwipeViewModel()
    @State private var isLoading = true
    @State private var isEmpty = false

    // 动画叠加层
    @State private var showKeepFlash = false
    @State private var showDeleteFlash = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if isEmpty {
                    emptyView
                } else {
                    swipeContent(screenSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .task {
            await loadSession()
        }
        .onChange(of: vm.session?.currentIndex) { _, _ in
            cleanSession = vm.session
        }
        .onChange(of: vm.isFinished) { _, finished in
            if finished {
                cleanSession = vm.session
                path.append(AppDestination.confirmDelete)
            }
        }
    }

    // MARK: - 加载状态

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.brandPrimary)
                .scaleEffect(1.5)
            Text("正在加载\(mode == .photo ? "照片" : "视频")…")
                .foregroundStyle(Color.textSecondary)
                .font(.subheadline)
        }
    }

    // MARK: - 空状态

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(Color.textMuted)
            Text("没有找到\(mode == .photo ? "照片" : "视频")")
                .font(.title3)
                .foregroundStyle(.white)
            Text("尝试调整筛选条件或检查相册权限")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Button {
                path.removeLast()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .foregroundStyle(Color.brandPrimary)
                .font(.body.weight(.medium))
            }
            .padding(.top, Spacing.md)
        }
    }

    // MARK: - 滑动内容

    @ViewBuilder
    private func swipeContent(screenSize: CGSize) -> some View {
        ZStack {
            // 照片卡片
            if let asset = vm.currentAsset {
                SwipeCardView(
                    asset: asset,
                    dragOffset: vm.dragOffset,
                    rotation: vm.rotationAngle(
                        translation: vm.dragOffset,
                        screenWidth: screenSize.width
                    ),
                    isOverThreshold: vm.isOverThreshold(
                        translation: vm.dragOffset,
                        screenSize: screenSize
                    ),
                    direction: vm.dragDirection
                )
                .id(vm.currentIndex) // 强制刷新
                .gesture(swipeGesture(screenSize: screenSize))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.toggleUI()
                    }
                }
            }

            // 保留闪光叠加
            if showKeepFlash {
                Color.brandPrimary.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 删除闪光叠加
            if showDeleteFlash {
                Color.destructiveRed.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // UI 叠加层
            if vm.showUI {
                VStack {
                    topBar
                    Spacer()
                    bottomInfo
                    progressBar(screenWidth: screenSize.width)
                }
            }
        }
    }

    // MARK: - 顶部栏

    private var topBar: some View {
        HStack {
            // 返回按钮
            Button {
                path.removeLast()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .foregroundStyle(.white)
                .font(.body.weight(.medium))
            }

            Spacer()

            // 删除计数胶囊
            if vm.markedCount > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text("\(vm.markedCount)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm + 2)
                .padding(.vertical, Spacing.xs + 2)
                .background(Color.destructiveRed)
                .clipShape(Capsule())
            }

            Spacer()

            // 进度文字
            Text("\(vm.currentIndex + 1)/\(vm.totalCount)")
                .foregroundStyle(Color.textSecondary)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.pagePadding)
        .padding(.top, Spacing.xl + 20) // 给状态栏留空间
        .background(
            LinearGradient(
                colors: [.black.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - 底部信息

    private var bottomInfo: some View {
        VStack(spacing: Spacing.xs) {
            if let asset = vm.currentAsset {
                if let date = asset.creationDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Text(formatFileSize(asset.fileSize))
                    .font(.caption2)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - 底部进度条

    private func progressBar(screenWidth: CGFloat) -> some View {
        GeometryReader { _ in
            let progress = vm.totalCount > 0
                ? CGFloat(vm.currentIndex + 1) / CGFloat(vm.totalCount)
                : 0
            RoundedRectangle(cornerRadius: CornerRadius.progressBar)
                .fill(Color.brandPrimary)
                .frame(width: screenWidth * progress, height: 3)
        }
        .frame(height: 3)
        .background(Color.white.opacity(0.1))
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - 手势

    private func swipeGesture(screenSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                vm.dragOffset = value.translation
                vm.dragDirection = vm.detectDirection(translation: value.translation)

                // 越过阈值时触发触觉
                let overThreshold = vm.isOverThreshold(
                    translation: value.translation,
                    screenSize: screenSize
                )
                if overThreshold {
                    HapticService.thresholdReached(direction: vm.dragDirection)
                }
            }
            .onEnded { value in
                let direction = vm.detectDirection(translation: value.translation)
                let overThreshold = vm.isOverThreshold(
                    translation: value.translation,
                    screenSize: screenSize
                )

                if overThreshold {
                    HapticService.gestureTriggered()
                    switch direction {
                    case .up:
                        triggerKeep(screenSize: screenSize)
                    case .left:
                        triggerDelete(screenSize: screenSize)
                    case .down:
                        triggerGoBack()
                    default:
                        snapBack()
                    }
                } else {
                    snapBack()
                }
            }
    }

    // MARK: - 触发动作

    private func triggerKeep(screenSize: CGSize) {
        if reduceMotion {
            // 无障碍模式：简单淡出替代飞出动画
            withAnimation(.easeOut(duration: 0.25)) {
                showKeepFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.keepCurrent()
                showKeepFlash = false
            }
        } else {
            // 飞出动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                vm.dragOffset = CGSize(width: 0, height: -screenSize.height)
            }
            // 绿色闪光
            showKeepFlash = true
            // 延迟后执行动作
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.keepCurrent()
                showKeepFlash = false
            }
        }
    }

    private func triggerDelete(screenSize: CGSize) {
        if reduceMotion {
            // 无障碍模式：简单淡出替代飞出动画
            withAnimation(.easeOut(duration: 0.25)) {
                showDeleteFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.deleteCurrent()
                showDeleteFlash = false
            }
        } else {
            // 飞出动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                vm.dragOffset = CGSize(width: -screenSize.width, height: 0)
            }
            // 红色闪光
            showDeleteFlash = true
            // 延迟后执行动作
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.deleteCurrent()
                showDeleteFlash = false
            }
        }
    }

    private func triggerGoBack() {
        guard vm.currentIndex > 0 else {
            HapticService.boundaryReached()
            snapBack()
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vm.goBack()
        }
    }

    private func snapBack() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vm.dragOffset = .zero
            vm.dragDirection = .none
        }
    }

    // MARK: - 加载会话

    private func loadSession() async {
        let batchSize = statsService.getSettings(in: modelContext).batchSize
        let session = await photoService.fetchRandomAssets(mode: mode, count: batchSize)
        if session.assets.isEmpty {
            isEmpty = true
        } else {
            vm.session = session
            cleanSession = session
        }
        isLoading = false
    }
}
