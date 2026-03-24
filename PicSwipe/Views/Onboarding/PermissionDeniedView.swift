// PicSwipe/Views/Onboarding/PermissionDeniedView.swift
import SwiftUI

/// 相册权限被拒绝时的提示页
struct PermissionDeniedView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                Text("🔒")
                    .font(.system(size: 64))

                VStack(spacing: Spacing.sm) {
                    Text("需要相册权限")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)

                    Text("请前往系统设置，开启 PicSwipe 的相册访问权限")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.pagePadding)
                }

                Spacer()

                PrimaryButton(title: "前往设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}
