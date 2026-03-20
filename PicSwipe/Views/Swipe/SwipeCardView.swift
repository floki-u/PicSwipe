// PicSwipe/Views/Swipe/SwipeCardView.swift
import SwiftUI
import Photos

/// 单张照片/视频卡片视图
/// 负责加载并展示全屏图片，应用偏移和旋转，显示阈值指示器
struct SwipeCardView: View {
    let asset: AssetItem
    let dragOffset: CGSize
    let rotation: Angle
    let isOverThreshold: Bool
    let direction: SwipeDirection

    @Environment(PhotoLibraryService.self) private var photoService
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 照片
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.appBackground
                    ProgressView()
                        .tint(.white)
                }

                // 阈值指示器
                if isOverThreshold {
                    thresholdIndicator
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(dragOffset)
            .rotationEffect(rotation)
            .onAppear {
                loadImage(targetSize: CGSize(
                    width: geometry.size.width * UIScreen.main.scale,
                    height: geometry.size.height * UIScreen.main.scale
                ))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 阈值指示器

    @ViewBuilder
    private var thresholdIndicator: some View {
        switch direction {
        case .up:
            // 保留指示
            VStack {
                Spacer()
                Text("保留 ✓")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brandPrimary.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                Spacer()
                Spacer()
            }
        case .left:
            // 删除指示
            VStack {
                Spacer()
                Text("删除 ✕")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.destructiveRed.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                Spacer()
                Spacer()
            }
        case .down:
            // 回看指示
            VStack {
                Spacer()
                Spacer()
                Text("回看 ↓")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color.textSecondary.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                Spacer()
            }
        default:
            EmptyView()
        }
    }

    // MARK: - 图片加载

    private func loadImage(targetSize: CGSize) {
        guard let phAsset = asset.phAsset else { return }
        _ = photoService.requestImage(for: phAsset, targetSize: targetSize) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}
