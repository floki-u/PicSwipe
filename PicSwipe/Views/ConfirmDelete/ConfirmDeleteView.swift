// PicSwipe/Views/ConfirmDelete/ConfirmDeleteView.swift
import SwiftUI
import Photos
import SwiftData

/// 确认删除页 — 逐张预览待删除照片
/// 支持左右滑动切换、单张撤回、全部撤回、确认删除
struct ConfirmDeleteView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var vm = ConfirmDeleteViewModel()
    @State private var isDeleting = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if vm.markedAssets.isEmpty {
                allKeptView
            } else {
                mainContent
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
                .foregroundStyle(.white)

            Text("没有照片被删除")
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

    // MARK: - 主内容

    private var mainContent: some View {
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

    // MARK: - 顶部标题

    private var headerSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("确认删除")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("左右滑动查看每张照片")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - 大图预览（TabView 可滑动）

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
            // 照片缩略图
            AssetThumbnailView(asset: asset, photoService: photoService)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            // 底部渐变信息
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let date = asset.creationDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Text(formatFileSize(asset.fileSize))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // 顶部操作栏
            HStack {
                // 计数标签
                Text("\(index + 1)/\(vm.markedAssets.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.destructiveRed)
                    .clipShape(Capsule())

                Spacer()

                // 撤回按钮
                Button {
                    vm.revokeMarking(for: asset.localIdentifier)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
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
                    .fill(index == vm.currentPreviewIndex ? Color.destructiveRed : Color.white.opacity(0.3))
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
                        Text("确认删除 (\(vm.markedAssets.count))")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isDeleting ? Color.destructiveRed.opacity(0.6) : Color.destructiveRed)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
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
            cleanSession = nil
            path.append(AppDestination.result(deletedCount: deletedCount, freedSpace: freedSpace))
        } catch {
            // 删除失败也跳转到结果页（显示 0）
            path.append(AppDestination.result(deletedCount: 0, freedSpace: 0))
        }
        isDeleting = false
    }

    private func goToNextBatch() {
        cleanSession = nil
        path.removeLast(path.count)
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
private struct AssetThumbnailView: View {
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
