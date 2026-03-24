// PicSwipe/Views/Onboarding/PermissionView.swift
import SwiftUI

/// 相册权限申请页
struct PermissionView: View {
    let onAuthorized: () -> Void
    let onSkip: () -> Void

    @Environment(PhotoLibraryService.self) private var photoService
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 标题
                VStack(spacing: Spacing.md) {
                    Text("需要相册权限")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)

                    Text("PicSwipe 需要访问你的照片库\n所有处理在本地完成，绝不上传")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // 特性列表
                VStack(spacing: Spacing.md) {
                    featureRow(emoji: "🔒", title: "本地处理", desc: "所有照片分析在设备上完成")
                    featureRow(emoji: "📵", title: "不联网", desc: "无需网络，保护你的隐私")
                    featureRow(emoji: "🗑", title: "可恢复", desc: "删除后 30 天内可从最近删除恢复")
                }
                .padding(.top, Spacing.xl)
                .padding(.horizontal, Spacing.pagePadding)

                Spacer()

                // 按钮区
                VStack(spacing: Spacing.md) {
                    Button {
                        Task { await requestPermission() }
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.8)
                            } else {
                                Text("授权相册")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.brandGradient)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                    }
                    .disabled(isRequesting)

                    Button("稍后再说") {
                        onSkip()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    // MARK: - 子组件

    private func featureRow(emoji: String, title: String, desc: String) -> some View {
        HStack(spacing: Spacing.md) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.thumbnail))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - 操作

    private func requestPermission() async {
        isRequesting = true
        let status = await photoService.requestAuthorization()
        isRequesting = false
        if status == .authorized || status == .limited {
            onAuthorized()
        } else {
            onSkip()
        }
    }
}
