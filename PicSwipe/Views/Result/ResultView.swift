// PicSwipe/Views/Result/ResultView.swift
import SwiftUI

/// 清理结果页 — 像素 RPG 风格 QUEST COMPLETE
struct ResultView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let deletedCount: Int
    let freedSpace: Int64
    let mode: CleanMode

    @State private var showIcon = false
    @State private var showNumbers = false
    @State private var showButtons = false

    private var isVideo: Bool { mode == .video }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // QUEST COMPLETE 像素装饰
                questCompleteHeader
                    .opacity(showIcon ? 1 : 0)
                    .offset(y: showIcon ? 0 : -10)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showIcon)

                // 成功图标
                resultIcon
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xl)

                // 主要统计数字
                statsSection
                    .opacity(showNumbers ? 1 : 0)
                    .offset(y: showNumbers ? 0 : 20)

                Spacer()

                // 操作按钮
                buttonSection
                    .opacity(showButtons ? 1 : 0)
                    .padding(.horizontal, Spacing.pagePadding)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - QUEST COMPLETE 标题

    private var questCompleteHeader: some View {
        VStack(spacing: Spacing.xs) {
            Text("✦ QUEST COMPLETE ✦")
                .font(.pixel(10))
                .foregroundStyle(Color.warningYellow)
            Text("🏆")
                .font(.system(size: 36))
        }
    }

    // MARK: - 结果图标

    private var resultIcon: some View {
        ZStack {
            // 光晕背景
            Circle()
                .fill((isVideo ? Color.destructiveRed : Color.brandPrimary).opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(showIcon ? 1 : 0.3)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: showIcon)

            // 主圆圈
            Circle()
                .fill(isVideo
                    ? LinearGradient(colors: [Color.destructiveRed, Color.destructiveRed.opacity(0.8)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient.brandGradient
                )
                .frame(width: 88, height: 88)
                .scaleEffect(showIcon ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: showIcon)

            // 图标
            Image(systemName: isVideo ? "trash.fill" : "checkmark")
                .font(.system(size: isVideo ? 32 : 38, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(showIcon ? 1 : 0)
                .opacity(showIcon ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.35), value: showIcon)
        }
    }

    // MARK: - 统计数字（像素字体）

    private var statsSection: some View {
        VStack(spacing: Spacing.md) {
            // 删除数量 — 垂直排列避免 baseline 错位
            VStack(spacing: Spacing.sm) {
                Text("已清理")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                Text("\(deletedCount)")
                    .font(.pixel(36))
                    .foregroundStyle(isVideo ? Color.destructiveRed : Color.brandPrimary)

                Text(isVideo ? "个视频" : "张照片")
                    .font(.headline)
                    .foregroundStyle(isVideo ? Color.destructiveRed.opacity(0.8) : Color.brandPrimary.opacity(0.8))
            }

            // 分割线
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(width: 60, height: 1)

            // 释放空间 — 像素徽章
            freedSpaceBadge
        }
    }

    /// 释放空间像素徽章
    private var freedSpaceBadge: some View {
        HStack(spacing: 6) {
            Text("+")
                .font(.pixel(10))
                .foregroundStyle(Color.warningYellow)
            Text(formatFileSize(freedSpace))
                .font(.pixel(10))
                .foregroundStyle(Color.warningYellow)
            Text("FREED")
                .font(.pixel(8))
                .foregroundStyle(Color.warningYellow.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.warningYellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.warningYellow.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 操作按钮（像素文案）

    private var buttonSection: some View {
        HStack(spacing: Spacing.md) {
            // 回到首页 → HOME
            Button {
                goHome()
            } label: {
                Text("HOME")
                    .font(.pixel(10))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.fillTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(Color.borderMedium, lineWidth: 1)
                    )
            }

            // 再来一组 → NEXT ▶
            Button {
                startNewBatch()
            } label: {
                Text("NEXT ▶")
                    .font(.pixel(10))
                    .foregroundStyle(isVideo ? .white : Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isVideo
                            ? Color.destructiveRed.opacity(0.15)
                            : Color.brandPrimary.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(
                                isVideo ? Color.destructiveRed : Color.brandPrimary,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: (isVideo ? Color.destructiveRed : Color.brandPrimary).opacity(0.3),
                        radius: 8, y: 2
                    )
            }
        }
    }

    // MARK: - 动画

    private func startAnimations() {
        withAnimation {
            showIcon = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showNumbers = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showButtons = true
            }
        }
    }

    // MARK: - 操作

    private func goHome() {
        cleanSession = nil
        path.removeLast(path.count)
    }

    private func startNewBatch() {
        cleanSession = nil
        // 先清空导航栈回到首页，再立刻推入新的滑动页
        path.removeLast(path.count)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            path.append(AppDestination.swipe(mode))
        }
    }
}
