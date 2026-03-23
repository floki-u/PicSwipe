// PicSwipe/Views/Result/ResultView.swift
import SwiftUI

/// 清理结果页 — 展示成功动画与统计数据
/// 照片模式：绿色勾号 + "已清理 N 张"
/// 视频模式：红色删除图标 + "已清理 N 个视频"
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

                // 成功图标
                resultIcon
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

    // MARK: - 统计数字

    private var statsSection: some View {
        VStack(spacing: Spacing.md) {
            // 张/个数
            VStack(spacing: Spacing.xs) {
                Text("已清理")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(deletedCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(isVideo ? Color.destructiveRed : Color.brandPrimary)
                    Text(isVideo ? "个视频" : "张照片")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(isVideo ? Color.destructiveRed : Color.brandPrimary)
                }
            }

            // 分割线
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 60, height: 1)

            // 释放空间
            VStack(spacing: Spacing.xs) {
                Text("释放空间")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Text(formatFileSize(freedSpace))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - 操作按钮

    private var buttonSection: some View {
        HStack(spacing: Spacing.md) {
            // 回到首页
            Button {
                goHome()
            } label: {
                Text("回到首页")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            }

            // 再来一组
            Button {
                startNewBatch()
            } label: {
                Text("再来一组")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(isVideo ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isVideo
                        ? AnyShapeStyle(Color.destructiveRed)
                        : AnyShapeStyle(LinearGradient.brandGradient)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
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
