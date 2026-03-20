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
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)

                    VStack(spacing: Spacing.sm) {
                        Text("PicSwipe")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

                        Text("让清理照片像刷短视频一样轻松")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 15)
                            .animation(.easeOut(duration: 0.5).delay(0.45), value: showContent)
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
                .animation(.easeOut(duration: 0.4).delay(0.6), value: showContent)
            }
        }
        .onAppear {
            showContent = true
        }
    }
}
