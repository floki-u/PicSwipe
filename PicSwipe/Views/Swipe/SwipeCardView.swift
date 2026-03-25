// PicSwipe/Views/Swipe/SwipeCardView.swift
import SwiftUI
import Photos
import PhotosUI

/// 单张照片/视频卡片视图
/// 负责加载并展示全屏内容，支持照片（含 Live Photo）和视频
/// 支持双指缩放查看细节
/// 照片模式：边缘渐变光晕 + 中心图标指示滑动方向
/// 视频模式：不显示边缘光晕（无左右滑动）
struct SwipeCardView: View {
    let asset: AssetItem
    let dragOffset: CGSize
    let rotation: Angle
    let dragProgress: CGFloat
    let direction: SwipeDirection
    /// 是否为视频清理模式（控制是否显示边缘光晕）
    var isVideoMode: Bool = false

    @Environment(PhotoLibraryService.self) private var photoService
    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var isLivePhoto: Bool = false
    @State private var isVideoPlaying: Bool = false

    // 缩放状态
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    // iCloud 下载状态
    @State private var isDownloadingFromCloud: Bool = false
    @State private var downloadProgress: Double = 0.0
    @State private var loadError: ImageLoadError? = nil
    @State private var imageRequestID: PHImageRequestID? = nil
    @State private var timeoutTask: Task<Void, Never>? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 内容区域
                if asset.mediaType == .video {
                    videoContent(geometry: geometry)
                } else {
                    photoContent(geometry: geometry)
                }

                // 照片模式：边缘渐变光晕
                if !isVideoMode {
                    edgeGlowOverlay(geometry: geometry)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(dragOffset)
            .rotationEffect(rotation)
            .onAppear {
                loadContent(targetSize: CGSize(
                    width: geometry.size.width * UIScreen.main.scale,
                    height: geometry.size.height * UIScreen.main.scale
                ))
            }
            .onDisappear {
                timeoutTask?.cancel()
                timeoutTask = nil
                if let requestID = imageRequestID {
                    photoService.cancelImageRequest(requestID)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 照片内容（含 Live Photo + 缩放）

    @ViewBuilder
    private func photoContent(geometry: GeometryProxy) -> some View {
        if isLivePhoto, let livePhoto = livePhoto {
            LivePhotoView(livePhoto: livePhoto)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(currentScale)
                .gesture(zoomGesture)
        } else if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(currentScale)
                .gesture(zoomGesture)
        } else if loadError != nil {
            iCloudErrorView()
        } else if isDownloadingFromCloud {
            iCloudDownloadingView()
        } else {
            Color.appBackground
            ProgressView()
                .tint(.white)
        }
    }

    // MARK: - 视频内容

    @ViewBuilder
    private func videoContent(geometry: GeometryProxy) -> some View {
        if let phAsset = asset.phAsset {
            EnhancedVideoPlayerView(
                asset: phAsset,
                isPlaying: $isVideoPlaying
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
        } else {
            Color.appBackground
            ProgressView()
                .tint(.white)
        }
    }

    // MARK: - 边缘渐变光晕（照片模式）

    @ViewBuilder
    private func edgeGlowOverlay(geometry: GeometryProxy) -> some View {
        // 上滑时：顶部绿色渐变
        if direction == .up && dragProgress > 0.05 {
            VStack {
                LinearGradient(
                    colors: [
                        Color.brandPrimary.opacity(Double(dragProgress) * 0.6),
                        Color.brandPrimary.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: geometry.size.height * 0.35)
                Spacer()
            }
            .allowsHitTesting(false)
        }

        // 左滑时：左侧红色渐变
        if direction == .left && dragProgress > 0.05 {
            HStack {
                LinearGradient(
                    colors: [
                        Color.destructiveRed.opacity(Double(dragProgress) * 0.6),
                        Color.destructiveRed.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.35)
                Spacer()
            }
            .allowsHitTesting(false)
        }

        // 下滑时：底部灰色渐变
        if direction == .down && dragProgress > 0.05 {
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.white.opacity(Double(dragProgress) * 0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: geometry.size.height * 0.35)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - 缩放手势

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                currentScale = min(max(newScale, 1.0), 4.0) // 限制 1x ~ 4x
            }
            .onEnded { value in
                let newScale = lastScale * value
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if newScale < 1.2 {
                        // 接近原始大小时自动回弹
                        currentScale = 1.0
                        lastScale = 1.0
                    } else {
                        currentScale = min(newScale, 4.0)
                        lastScale = currentScale
                    }
                }
            }
    }

    // MARK: - iCloud 状态视图

    /// iCloud 下载中视图 — ☁️ 图标 + 进度条 + RPG 文案
    @ViewBuilder
    private func iCloudDownloadingView() -> some View {
        Color.appBackground
        VStack(spacing: Spacing.md) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 40))
                .foregroundStyle(.white)

            Text("DOWNLOADING FROM CLOUD...")
                .font(.pixel(8))
                .foregroundStyle(Color.textOnMedia)

            VStack(spacing: Spacing.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.progressBar)
                            .fill(Color.fillTertiary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: CornerRadius.progressBar)
                            .fill(Color.brandPrimary)
                            .frame(width: geo.size.width * downloadProgress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(downloadProgress * 100))%")
                    .font(.pixel(8))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(width: 200)
        }
    }

    /// iCloud 加载失败视图 — ❌ 图标 + 错误文案 + 跳过提示
    @ViewBuilder
    private func iCloudErrorView() -> some View {
        Color.appBackground
        VStack(spacing: Spacing.md) {
            Image(systemName: "xmark.icloud")
                .font(.system(size: 40))
                .foregroundStyle(Color.destructiveRed)

            Text("QUEST FAILED")
                .font(.pixel(10))
                .foregroundStyle(Color.destructiveRed)

            Text("SWIPE UP TO SKIP")
                .font(.pixel(8))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - 内容加载

    private func loadContent(targetSize: CGSize) {
        guard let phAsset = asset.phAsset else { return }

        if asset.mediaType == .video {
            _ = photoService.requestImage(for: phAsset, targetSize: targetSize) { loadedImage in
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
            return
        }

        if phAsset.mediaSubtypes.contains(.photoLive) {
            isLivePhoto = true
            loadLivePhoto(phAsset: phAsset, targetSize: targetSize)
        }

        let requestID = photoService.requestImage(
            for: phAsset,
            targetSize: targetSize,
            progressHandler: { progress in
                self.isDownloadingFromCloud = true
                self.downloadProgress = progress
            }
        ) { loadedImage, error in
            DispatchQueue.main.async {
                guard self.loadError == nil else { return }

                self.timeoutTask?.cancel()
                self.timeoutTask = nil

                if let loadedImage = loadedImage {
                    self.image = loadedImage
                    self.isDownloadingFromCloud = false
                } else if let error = error {
                    self.loadError = error
                    self.isDownloadingFromCloud = false
                }
            }
        }
        imageRequestID = requestID

        timeoutTask = Task {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self.image == nil, self.loadError == nil else { return }
                if let requestID = self.imageRequestID {
                    self.photoService.cancelImageRequest(requestID)
                }
                self.loadError = .timeout
                self.isDownloadingFromCloud = false
            }
        }
    }

    private func loadLivePhoto(phAsset: PHAsset, targetSize: CGSize) {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestLivePhoto(
            for: phAsset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                if let result = result {
                    self.livePhoto = result
                }
            }
        }
    }

}

// MARK: - Live Photo UIViewRepresentable

/// 使用 PHLivePhotoView 展示 Live Photo，支持长按播放
struct LivePhotoView: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.livePhoto = livePhoto
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
    }
}
