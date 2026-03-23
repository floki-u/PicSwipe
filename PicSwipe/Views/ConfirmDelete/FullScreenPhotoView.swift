// PicSwipe/Views/ConfirmDelete/FullScreenPhotoView.swift
import SwiftUI
import Photos

/// 全屏照片查看器 — 黑色遮罩 + 照片 .fit 展示
/// 支持双指缩放（1x~4x）和下拉手势关闭
struct FullScreenPhotoView: View {
    let asset: AssetItem
    let photoService: PhotoLibraryService
    let onDismiss: () -> Void

    @State private var image: UIImage?
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    /// 下拉关闭阈值
    private let dismissThreshold: CGFloat = 150

    var body: some View {
        ZStack {
            // 黑色遮罩背景
            Color.black
                .opacity(opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景也可关闭（当未缩放时）
                }

            // 照片内容
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(currentScale)
                    .offset(y: dragOffset)
                    .gesture(zoomGesture)
                    .gesture(dismissDragGesture)
            } else {
                ProgressView()
                    .tint(.white)
            }

            // 右上角关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, Spacing.pagePadding)
                    .padding(.top, Spacing.xl + 20)
                }
                Spacer()
            }
        }
        .onAppear {
            loadFullImage()
        }
    }

    // MARK: - 缩放手势

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                currentScale = min(max(newScale, 1.0), 4.0)
            }
            .onEnded { value in
                let newScale = lastScale * value
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if newScale < 1.2 {
                        currentScale = 1.0
                        lastScale = 1.0
                    } else {
                        currentScale = min(newScale, 4.0)
                        lastScale = currentScale
                    }
                }
            }
    }

    // MARK: - 下拉关闭手势

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // 仅在未缩放时允许下拉关闭
                guard currentScale <= 1.05 else { return }
                let translation = value.translation.height
                if translation > 0 {
                    dragOffset = translation
                    // 随下拉距离减淡背景
                    opacity = max(0.3, 1.0 - Double(translation / 400))
                }
            }
            .onEnded { value in
                guard currentScale <= 1.05 else { return }
                if value.translation.height > dismissThreshold {
                    // 超过阈值，关闭
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = UIScreen.main.bounds.height
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                } else {
                    // 回弹
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                        opacity = 1.0
                    }
                }
            }
    }

    // MARK: - 加载全尺寸图片

    private func loadFullImage() {
        guard let phAsset = asset.phAsset else { return }
        let screenScale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds.size
        let targetSize = CGSize(
            width: screenSize.width * screenScale,
            height: screenSize.height * screenScale
        )
        _ = photoService.requestImage(for: phAsset, targetSize: targetSize) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}
