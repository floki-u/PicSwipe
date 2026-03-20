// PicSwipe/Views/Onboarding/TutorialView.swift
import SwiftUI
import SwiftData

/// 手势教程页 — 三页滑动教学
struct TutorialView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(StatisticsService.self) private var statsService
    @State private var currentPage = 0

    private let pages: [TutorialPage] = [
        TutorialPage(
            direction: .up,
            symbol: "上滑",
            action: "保留",
            mark: "✓",
            markColor: Color.brandPrimary,
            description: "喜欢的照片向上滑，留下来"
        ),
        TutorialPage(
            direction: .left,
            symbol: "左滑",
            action: "删除",
            mark: "×",
            markColor: Color.destructiveRed,
            description: "不想要的照片向左滑，标记删除"
        ),
        TutorialPage(
            direction: .down,
            symbol: "下滑",
            action: "回看",
            mark: "↩",
            markColor: Color.warningYellow,
            description: "想重新看上一张，向下滑"
        ),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // 跳过按钮
            VStack {
                HStack {
                    Spacer()
                    Button("跳过") {
                        finishTutorial()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, 60)
                    .padding(.trailing, Spacing.pagePadding)
                }
                Spacer()
            }

            // 内容
            VStack(spacing: 0) {
                Spacer()

                // 页面内容（TabView）
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        tutorialPage(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)

                // 页面指示点
                pageIndicator
                    .padding(.top, Spacing.lg)

                Spacer()

                // 底部按钮
                bottomButton
                    .padding(.horizontal, Spacing.pagePadding)
                    .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: - 教程页

    private func tutorialPage(_ page: TutorialPage) -> some View {
        VStack(spacing: Spacing.xl) {
            // 动画箭头区域
            arrowAnimation(for: page)
                .frame(height: 200)

            // 文字说明
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Text(page.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("=")
                        .font(.title)
                        .foregroundStyle(Color.textSecondary)
                    Text(page.action)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(page.markColor)
                    Text(page.mark)
                        .font(.title)
                        .foregroundStyle(page.markColor)
                }

                Text(page.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.pagePadding)
        }
    }

    @ViewBuilder
    private func arrowAnimation(for page: TutorialPage) -> some View {
        AnimatedArrowView(direction: page.direction, color: page.markColor)
    }

    // MARK: - 页面指示点

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.brandPrimary : Color.white.opacity(0.3))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    // MARK: - 底部按钮

    private var bottomButton: some View {
        Group {
            if currentPage < pages.count - 1 {
                PrimaryButton(title: "下一步") {
                    withAnimation {
                        currentPage += 1
                    }
                }
            } else {
                PrimaryButton(title: "开始清理") {
                    finishTutorial()
                }
            }
        }
    }

    // MARK: - 操作

    private func finishTutorial() {
        let settings = statsService.getSettings(in: modelContext)
        settings.hasSeenTutorial = true
        try? modelContext.save()
        onFinish()
    }
}

// MARK: - 教程数据模型

private struct TutorialPage {
    let direction: ArrowDirection
    let symbol: String
    let action: String
    let mark: String
    let markColor: Color
    let description: String
}

enum ArrowDirection {
    case up, left, down
}

// MARK: - 动画箭头视图

private struct AnimatedArrowView: View {
    let direction: ArrowDirection
    let color: Color

    @State private var isAnimating = false

    private var systemName: String {
        switch direction {
        case .up: return "arrow.up"
        case .left: return "arrow.left"
        case .down: return "arrow.down"
        }
    }

    private var offset: CGSize {
        let amount: CGFloat = isAnimating ? 20 : -20
        switch direction {
        case .up: return CGSize(width: 0, height: -amount)
        case .left: return CGSize(width: -amount, height: 0)
        case .down: return CGSize(width: 0, height: amount)
        }
    }

    var body: some View {
        ZStack {
            // 背景圆圈
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 120, height: 120)

            // 手机模拟框
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.surfaceBackground)
                .frame(width: 90, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )

            // 箭头
            Image(systemName: systemName)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(color)
                .offset(offset)
                .opacity(isAnimating ? 1 : 0.3)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}
