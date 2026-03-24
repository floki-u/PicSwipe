// PicSwipe/Views/ConfirmDelete/ConfirmDeleteView.swift
import SwiftUI
import Photos
import SwiftData

/// 确认删除页 — 逐张预览待删除照片/视频
/// 支持左右滑动切换、单张撤回、全部撤回、确认删除
/// 照片模式：点击照片可查看全屏大图
/// 视频模式：列表式展示，适合视频缩略图预览
struct ConfirmDeleteView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var vm = ConfirmDeleteViewModel()
    @State private var isDeleting = false
    @State private var fullScreenAsset: AssetItem?

    /// 当前清理模式
    private var currentMode: CleanMode {
        cleanSession?.mode ?? .photo
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if vm.markedAssets.isEmpty {
                allKeptView
            } else {
                if currentMode == .video {
                    videoConfirmContent
                } else {
                    photoConfirmContent
                }
            }

            // 全屏照片查看器叠加层（仅照片模式）
            if let asset = fullScreenAsset {
                FullScreenPhotoView(
                    asset: asset,
                    photoService: photoService,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            fullScreenAsset = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            vm.loadFromSession(cleanSession)
        }
    }

    // MARK: - 全部保留状态

    private var allKeptView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Text("🎉")
                .font(.system(size: 72))

            Text("这组全部保留！")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            Text(currentMode == .video ? "没有视频被删除" : "没有照片被删除")
                .font(.body)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            PrimaryButton(title: "再来一组") {
                goToNextBatch()
            }
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: - 照片确认删除内容

    private var photoConfirmContent: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.pagePadding)

            previewSection
                .padding(.top, Spacing.md)

            pageIndicator
                .padding(.top, Spacing.sm)

            thumbnailStrip
                .padding(.top, Spacing.md)

            sizeInfo
                .padding(.top, Spacing.md)

            bottomActions
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: - 视频确认删除内容

    private var videoConfirmContent: some View {
        VStack(spacing: 0) {
            // 顶部标题
            VStack(spacing: Spacing.xs) {
                Text("确认删除")
                    .font(.pixel(12))
                    .foregroundStyle(Color.destructiveRed)
                Text("以下 \(vm.markedAssets.count) 个视频将被移到最近删除")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, Spacing.lg)
            .padding(.horizontal, Spacing.pagePadding)

            // 视频列表
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(Array(vm.markedAssets.enumerated()), id: \.element.id) { index, asset in
                        videoDeleteRow(for: asset, index: index)
                    }
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.top, Spacing.md)
            }

            // 释放空间 + 操作按钮
            VStack(spacing: Spacing.md) {
                sizeInfo
                videoBottomActions
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.pagePadding)
            .padding(.bottom, Spacing.lg)
        }
    }

    /// 视频列表单行
    private func videoDeleteRow(for asset: AssetItem, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // 视频缩略图
            AssetThumbnailView(asset: asset, photoService: photoService)
                .frame(width: 80, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    // 播放图标
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textOnMedia)
                        .padding(4)
                        .background(Color.overlayScrim)
                        .clipShape(Circle())
                )

            // 视频信息
            VStack(alignment: .leading, spacing: 2) {
                if let date = asset.creationDate {
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                }
                HStack(spacing: Spacing.sm) {
                    Text(formatFileSize(asset.fileSize))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    if let phAsset = asset.phAsset {
                        Text(formatVideoDuration(phAsset.duration))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            Spacer()

            // 撤回按钮
            Button {
                vm.revokeMarking(for: asset.localIdentifier)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption2.weight(.bold))
                    Text("撤回")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.fillSecondary)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    /// 视频模式底部操作按钮
    private var videoBottomActions: some View {
        VStack(spacing: Spacing.md) {
            // 确认删除按钮
            Button {
                Task { await performDelete() }
            } label: {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("确认删除 \(vm.markedAssets.count) 个视频")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isDeleting ? AnyShapeStyle(Color.destructiveRed.opacity(0.6)) : AnyShapeStyle(LinearGradient.destructiveGradient))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(Color.destructiveRed.opacity(0.6), lineWidth: 1)
                )
            }
            .disabled(isDeleting)

            // 辅助操作链接
            HStack(spacing: Spacing.xl) {
                Button("再来一组") {
                    goToNextBatch()
                }
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

                Button("全部撤回") {
                    revokeAllAndGoBack()
                }
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    /// 视频时长格式化
    private func formatVideoDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - 照片顶部标题

    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("确认删除")
                .font(.pixel(12))
                .foregroundStyle(Color.destructiveRed)
            Text("左右滑动查看，点击照片查看大图")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - 照片大图预览（TabView 可滑动）

    private var previewSection: some View {
        TabView(selection: $vm.currentPreviewIndex) {
            ForEach(Array(vm.markedAssets.enumerated()), id: \.element.id) { index, asset in
                previewCard(for: asset, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 260)
        .padding(.horizontal, Spacing.pagePadding)
    }

    private func previewCard(for asset: AssetItem, index: Int) -> some View {
        ZStack(alignment: .top) {
            // 照片缩略图（点击查看全屏）
            AssetThumbnailView(asset: asset, photoService: photoService)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        fullScreenAsset = asset
                    }
                }

            // 底部渐变信息
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let date = asset.creationDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(Color.textOnMedia.opacity(0.9))
                        }
                        Text(formatFileSize(asset.fileSize))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textOnMedia)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.overlayHeavy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .allowsHitTesting(false)

            // 顶部操作栏
            HStack {
                // 计数标签
                Text("\(index + 1)/\(vm.markedAssets.count)")
                    .font(.pixel(7))
                    .foregroundStyle(Color.textOnMedia)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.destructiveRed)
                    .clipShape(Capsule())

                Spacer()

                // 撤回胶囊按钮
                Button {
                    vm.revokeMarking(for: asset.localIdentifier)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption2.weight(.bold))
                        Text("撤回")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.textOnMedia)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.overlayHeavy)
                    .clipShape(Capsule())
                }
            }
            .padding(12)
        }
    }

    // MARK: - 页面指示点

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<vm.markedAssets.count, id: \.self) { index in
                Circle()
                    .fill(index == vm.currentPreviewIndex ? Color.destructiveRed : Color.indicatorInactive)
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: vm.currentPreviewIndex)
            }
        }
    }

    // MARK: - 缩略图条

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(vm.markedAssets.enumerated()), id: \.element.id) { index, asset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.currentPreviewIndex = index
                        }
                    } label: {
                        AssetThumbnailView(asset: asset, photoService: photoService)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.thumbnail))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.thumbnail)
                                    .stroke(
                                        index == vm.currentPreviewIndex
                                            ? Color.destructiveRed
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .opacity(index == vm.currentPreviewIndex ? 1.0 : 0.5)
                    }
                }
            }
            .padding(.horizontal, Spacing.pagePadding)
        }
        .frame(height: 44)
    }

    // MARK: - 预计释放空间

    private var sizeInfo: some View {
        HStack(spacing: 4) {
            Text("预计释放")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Text(formatFileSize(vm.totalSize))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.destructiveRed)
        }
    }

    // MARK: - 底部操作区

    private var bottomActions: some View {
        VStack(spacing: Spacing.md) {
            // 确认删除按钮
            Button {
                Task { await performDelete() }
            } label: {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("确认删除 \(vm.markedAssets.count) 张照片")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isDeleting ? AnyShapeStyle(Color.destructiveRed.opacity(0.6)) : AnyShapeStyle(LinearGradient.destructiveGradient))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(Color.destructiveRed.opacity(0.6), lineWidth: 1)
                )
            }
            .disabled(isDeleting)

            // 辅助操作链接
            HStack(spacing: Spacing.xl) {
                Button("再来一组") {
                    goToNextBatch()
                }
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

                Button("全部撤回") {
                    revokeAllAndGoBack()
                }
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    // MARK: - 操作

    private func performDelete() async {
        isDeleting = true
        do {
            let deletedCount = try await photoService.deleteAssets(vm.markedAssets)
            let freedSpace = vm.totalSize
            statsService.recordClean(
                deletedCount: deletedCount,
                freedSpace: freedSpace,
                mode: cleanSession?.mode ?? .photo,
                in: modelContext
            )
            // 标记用户已完成过一次删除，后续跳过确认页
            let settings = statsService.getSettings(in: modelContext)
            if !settings.hasConfirmedDeleteBefore {
                settings.hasConfirmedDeleteBefore = true
                try? modelContext.save()
            }
            HapticService.deleteSuccess()
            let resultMode = cleanSession?.mode ?? .photo
            cleanSession = nil
            path.append(AppDestination.result(deletedCount: deletedCount, freedSpace: freedSpace, mode: resultMode))
        } catch {
            HapticService.deleteError()
            path.append(AppDestination.result(deletedCount: 0, freedSpace: 0, mode: currentMode))
        }
        isDeleting = false
    }

    private func goToNextBatch() {
        let nextMode = currentMode
        cleanSession = nil
        path.removeLast(path.count)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            path.append(AppDestination.swipe(nextMode))
        }
    }

    private func revokeAllAndGoBack() {
        if var session = cleanSession {
            for i in 0..<session.assets.count {
                session.assets[i].markedForDeletion = false
            }
            session.currentIndex = 0
            cleanSession = session
        }
        vm.revokeAll()
        path.removeLast()
    }
}

// MARK: - 资源缩略图视图

/// 从 PhotoLibraryService 异步加载 PHAsset 缩略图
struct AssetThumbnailView: View {
    let asset: AssetItem
    let photoService: PhotoLibraryService

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.surfaceBackground)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(Color.textMuted)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let phAsset = asset.phAsset else { return }
        _ = photoService.requestImage(
            for: phAsset,
            targetSize: CGSize(width: 300, height: 300)
        ) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
