// PicSwipe/Views/Swipe/SwipeView.swift
import SwiftUI
import SwiftData

/// 滑动浏览页 — 核心交互页面
/// 照片模式：上滑保留、左滑删除、下滑回看、点击切换纯净模式
/// 视频模式：上下滑动切换视频、底部浮动按钮标记删除/撤回
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
    /// 防止触觉反馈在每帧重复触发
    @State private var hasTriggeredHaptic = false

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
            // 照片/视频卡片
            if let asset = vm.currentAsset {
                let cardView = SwipeCardView(
                    asset: asset,
                    dragOffset: vm.dragOffset,
                    rotation: mode == .photo
                        ? vm.rotationAngle(translation: vm.dragOffset, screenWidth: screenSize.width)
                        : .zero,
                    dragProgress: vm.dragProgress(
                        translation: vm.rawTranslation,
                        screenSize: screenSize
                    ),
                    direction: vm.dragDirection,
                    isVideoMode: mode == .video
                )
                .id(vm.currentIndex) // 强制刷新

                if mode == .photo {
                    cardView
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.toggleUI()
                            }
                        }
                        .gesture(photoSwipeGesture(screenSize: screenSize))
                } else {
                    cardView
                        .gesture(videoSwipeGesture(screenSize: screenSize))
                }
            }

            // UI 叠加层
            if vm.showUI {
                VStack {
                    topBar
                    Spacer()
                    if mode == .photo {
                        bottomInfo
                    }
                    progressBar(screenWidth: screenSize.width)
                }
            }

            // 视频模式：底部浮动操作按钮
            if mode == .video {
                videoFloatingButtons
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
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .font(.body.weight(.medium))
                    .padding(8)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
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
        .padding(.top, Spacing.xl + 20)
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

    // MARK: - 照片模式手势

    /// 跟手衰减系数
    private let dragDampingFactor: CGFloat = 0.5

    private func photoSwipeGesture(screenSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                vm.rawTranslation = value.translation
                vm.dragOffset = CGSize(
                    width: value.translation.width * dragDampingFactor,
                    height: value.translation.height * dragDampingFactor
                )
                vm.dragDirection = vm.detectDirection(translation: value.translation)

                // 越过阈值时触发触觉（仅一次，防止卡死）
                let overThreshold = vm.isOverThreshold(
                    translation: value.translation,
                    screenSize: screenSize
                )
                if overThreshold && !hasTriggeredHaptic {
                    hasTriggeredHaptic = true
                    HapticService.thresholdReached(direction: vm.dragDirection)
                } else if !overThreshold {
                    hasTriggeredHaptic = false
                }
            }
            .onEnded { value in
                hasTriggeredHaptic = false
                let direction = vm.detectDirection(translation: value.translation)
                let overThreshold = vm.isOverThreshold(
                    translation: value.translation,
                    screenSize: screenSize
                )
                let predictedEnd = value.predictedEndTranslation
                let fastSwipe = vm.isOverThreshold(
                    translation: predictedEnd,
                    screenSize: screenSize
                )

                if overThreshold || fastSwipe {
                    HapticService.gestureTriggered()
                    switch direction {
                    case .up:
                        triggerKeep(screenSize: screenSize, predictedEnd: predictedEnd)
                    case .left:
                        triggerDelete(screenSize: screenSize, predictedEnd: predictedEnd)
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

    // MARK: - 视频模式手势（仅上下滑动）

    private func videoSwipeGesture(screenSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                vm.rawTranslation = CGSize(width: 0, height: value.translation.height)
                vm.dragOffset = CGSize(
                    width: 0,
                    height: value.translation.height * dragDampingFactor
                )
                let verticalDirection = value.translation.height < 0 ? SwipeDirection.up : .down
                if abs(value.translation.height) > 10 {
                    vm.dragDirection = verticalDirection
                }
            }
            .onEnded { value in
                let absY = abs(value.translation.height)
                let thresholdY = screenSize.height / 6
                let predictedAbsY = abs(value.predictedEndTranslation.height)

                if absY > thresholdY || predictedAbsY > thresholdY {
                    HapticService.gestureTriggered()
                    if value.translation.height < 0 {
                        triggerVideoNext(screenSize: screenSize)
                    } else {
                        triggerVideoBack()
                    }
                } else {
                    snapBack()
                }
            }
    }

    // MARK: - 视频浮动操作按钮（右侧垂直居中）

    private var videoFloatingButtons: some View {
        HStack {
            Spacer()

            VStack(spacing: Spacing.lg) {
                // 删除按钮
                Button {
                    HapticService.gestureTriggered()
                    triggerVideoDelete(screenSize: UIScreen.main.bounds.size)
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.destructiveRed)
                        .clipShape(Circle())
                }

                // 撤回按钮（仅在有标记时显示）
                if vm.markedCount > 0 {
                    Button {
                        vm.undoLastMark()
                        HapticService.gestureTriggered()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, Spacing.pagePadding)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.markedCount)
        }
    }

    // MARK: - 照片模式触发动作

    private func triggerKeep(screenSize: CGSize, predictedEnd: CGSize) {
        if reduceMotion {
            vm.keepCurrent()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                vm.dragOffset = CGSize(
                    width: predictedEnd.width * 0.5 * dragDampingFactor,
                    height: -screenSize.height * 1.2
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.keepCurrent()
            }
        }
    }

    private func triggerDelete(screenSize: CGSize, predictedEnd: CGSize) {
        if reduceMotion {
            vm.deleteCurrent()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                vm.dragOffset = CGSize(
                    width: -screenSize.width * 1.2,
                    height: predictedEnd.height * 0.5 * dragDampingFactor
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.deleteCurrent()
            }
        }
    }

    private func triggerGoBack() {
        guard vm.currentIndex > 0 else {
            HapticService.boundaryReached()
            snapBack()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            vm.goBack()
        }
    }

    // MARK: - 视频模式触发动作

    private func triggerVideoNext(screenSize: CGSize) {
        if reduceMotion {
            vm.advanceToNext()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                vm.dragOffset = CGSize(width: 0, height: -screenSize.height * 1.2)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.advanceToNext()
            }
        }
    }

    private func triggerVideoBack() {
        guard vm.currentIndex > 0 else {
            HapticService.boundaryReached()
            snapBack()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            vm.goBack()
        }
    }

    private func triggerVideoDelete(screenSize: CGSize) {
        if reduceMotion {
            vm.markDeleteAndAdvance()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                vm.dragOffset = CGSize(width: -screenSize.width * 1.2, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.markDeleteAndAdvance()
            }
        }
    }

    private func snapBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            vm.dragOffset = .zero
            vm.dragDirection = .none
            vm.rawTranslation = .zero
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
