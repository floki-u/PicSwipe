// PicSwipe/Views/Onboarding/WelcomeView.swift
import SwiftUI

/// 欢迎页 — 引导用户开始
struct WelcomeView: View {
    let onNext: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo 区域
                VStack(spacing: Spacing.lg) {
                    Text("🌿")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.05), value: showContent)

                    VStack(spacing: Spacing.sm) {
                        Text("PicS")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.smooth(duration: 0.35).delay(0.15), value: showContent)

                        Text("让清理照片像刷短视频一样轻松")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 15)
                            .animation(.smooth(duration: 0.35).delay(0.22), value: showContent)
                    }
                }

                Spacer()

                // 开始按钮
                PrimaryButton(title: "开始使用") {
                    onNext()
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.bottom, Spacing.xl)
                .opacity(showContent ? 1 : 0)
                .animation(.smooth(duration: 0.35).delay(0.3), value: showContent)
            }
        }
        .onAppear {
            showContent = true
        }
    }
}
