// PicSwipe/Views/Result/ResultView.swift
import SwiftUI

/// 清理结果页 — 展示成功动画与统计数据
struct ResultView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let deletedCount: Int
    let freedSpace: Int64

    @State private var showCheck = false
    @State private var showNumbers = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 成功图标
                checkMarkIcon
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

    // MARK: - 成功图标

    private var checkMarkIcon: some View {
        ZStack {
            // 光晕背景
            Circle()
                .fill(Color.brandPrimary.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(showCheck ? 1 : 0.3)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: showCheck)

            // 绿色圆圈
            Circle()
                .fill(LinearGradient.brandGradient)
                .frame(width: 88, height: 88)
                .scaleEffect(showCheck ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: showCheck)

            // 勾号
            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.black)
                .scaleEffect(showCheck ? 1 : 0)
                .opacity(showCheck ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.35), value: showCheck)
        }
    }

    // MARK: - 统计数字

    private var statsSection: some View {
        VStack(spacing: Spacing.md) {
            // 张数
            VStack(spacing: Spacing.xs) {
                Text("已清理")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(deletedCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.brandPrimary)
                    Text("张")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.brandPrimary)
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
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            }
        }
    }

    // MARK: - 动画

    private func startAnimations() {
        withAnimation {
            showCheck = true
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
        path.removeLast(path.count)
    }
}
