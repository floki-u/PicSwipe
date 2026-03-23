// PicSwipe/Views/Swipe/VideoPlayerView.swift
import SwiftUI
import AVFoundation
import Photos
import Combine

/// 增强版视频播放器 — SwiftUI 包裹层
/// 功能：可拖拽进度条、有声播放（可切换静音）、点击暂停/继续、长按 2x 加速
struct EnhancedVideoPlayerView: View {
    let asset: PHAsset
    @Binding var isPlaying: Bool

    @State private var playerManager = VideoPlayerManager()
    @State private var isMuted: Bool = false
    @State private var isSpeedUp: Bool = false
    @State private var isPaused: Bool = false
    @State private var progress: Double = 0
    @State private var isDraggingSeekBar: Bool = false
    @State private var currentTimeText: String = "0:00"
    @State private var totalTimeText: String = "0:00"

    var body: some View {
        ZStack {
            // 视频播放层
            VideoPlayerLayerView(playerManager: playerManager)
                .onAppear {
                    playerManager.loadVideo(for: asset)
                    playerManager.setMuted(isMuted)
                }
                .onDisappear {
                    playerManager.pause()
                }

            // 暂停时显示大播放按钮
            if isPaused {
                Image(systemName: "play.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.85))
                    .allowsHitTesting(false)
            }

            // 控件叠加层
            VStack {
                Spacer()
                bottomControls
            }

            // 长按 2x 速标签
            if isSpeedUp {
                VStack {
                    HStack {
                        Text("2x ⏩")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.7))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.leading, Spacing.pagePadding)
                    .padding(.top, Spacing.xl + 60)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            togglePause()
        }
        .simultaneousGesture(longPressSpeedGesture)
        .onChange(of: isMuted) { _, muted in
            playerManager.setMuted(muted)
        }
        .onReceive(playerManager.progressPublisher) { value in
            if !isDraggingSeekBar {
                progress = value
            }
        }
        .onReceive(playerManager.timeTextPublisher) { current, total in
            currentTimeText = current
            totalTimeText = total
        }
    }

    // MARK: - 点击暂停/继续

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            playerManager.pause()
        } else {
            playerManager.play()
        }
    }

    // MARK: - 底部控制栏

    private var bottomControls: some View {
        VStack(spacing: 6) {
            seekBar

            HStack {
                Text("\(currentTimeText) / \(totalTimeText)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button {
                    isMuted.toggle()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.pagePadding)
        }
        .padding(.bottom, Spacing.xl + 40)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - 可拖拽进度条

    private var seekBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)

                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 3)

                Circle()
                    .fill(.white)
                    .frame(width: isDraggingSeekBar ? 14 : 8, height: isDraggingSeekBar ? 14 : 8)
                    .offset(x: max(0, geo.size.width * CGFloat(progress) - (isDraggingSeekBar ? 7 : 4)))
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingSeekBar = true
                        let fraction = max(0, min(1, Double(value.location.x / geo.size.width)))
                        progress = fraction
                        playerManager.seek(to: fraction)
                    }
                    .onEnded { _ in
                        isDraggingSeekBar = false
                    }
            )
        }
        .frame(height: 20)
        .padding(.horizontal, Spacing.pagePadding)
    }

    // MARK: - 长按 2x 速手势

    private var longPressSpeedGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .onEnded { _ in
                isSpeedUp = true
                playerManager.setRate(2.0)
            }
            .sequenced(before: DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    isSpeedUp = false
                    playerManager.setRate(1.0)
                }
            )
    }
}

// MARK: - 视频播放管理器

@Observable
final class VideoPlayerManager {
    var player: AVPlayer?

    let progressPublisher = PassthroughSubject<Double, Never>()
    let timeTextPublisher = PassthroughSubject<(String, String), Never>()

    private var timeObserver: Any?
    private var loopObserver: NSObjectProtocol?

    func loadVideo(for asset: PHAsset) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] playerItem, _ in
            guard let self = self, let playerItem = playerItem else { return }
            DispatchQueue.main.async {
                let player = AVPlayer(playerItem: playerItem)
                player.isMuted = false
                self.player = player

                self.loopObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }

                let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                self.timeObserver = player.addPeriodicTimeObserver(
                    forInterval: interval,
                    queue: .main
                ) { [weak self] time in
                    guard let self = self,
                          let duration = player.currentItem?.duration,
                          duration.seconds.isFinite && duration.seconds > 0 else { return }
                    let currentSeconds = time.seconds
                    let totalSeconds = duration.seconds
                    self.progressPublisher.send(currentSeconds / totalSeconds)
                    self.timeTextPublisher.send((
                        self.formatTime(currentSeconds),
                        self.formatTime(totalSeconds)
                    ))
                }

                player.play()
            }
        }
    }

    func play() { player?.play() }
    func pause() { player?.pause() }
    func setMuted(_ muted: Bool) { player?.isMuted = muted }
    func setRate(_ rate: Float) { player?.rate = rate }

    func seek(to fraction: Double) {
        guard let player = player,
              let duration = player.currentItem?.duration,
              duration.seconds.isFinite && duration.seconds > 0 else { return }
        let targetTime = CMTime(seconds: duration.seconds * fraction, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime, toleranceBefore: .init(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                     toleranceAfter: .init(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    deinit {
        if let observer = timeObserver { player?.removeTimeObserver(observer) }
        if let observer = loopObserver { NotificationCenter.default.removeObserver(observer) }
    }
}

// MARK: - 视频播放器 UIView 包装

struct VideoPlayerLayerView: UIViewRepresentable {
    let playerManager: VideoPlayerManager

    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        if let player = playerManager.player, uiView.player !== player {
            uiView.player = player
        }
    }
}

class VideoPlayerUIView: UIView {
    var player: AVPlayer? {
        didSet { playerLayer.player = player }
    }

    private var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass { AVPlayerLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { player?.pause() }
    }
}
