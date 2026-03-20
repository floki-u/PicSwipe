// PicSwipe/Views/DesignSystem.swift
import SwiftUI

// MARK: - 品牌色

extension Color {
    /// 品牌主色 #43e97b
    static let brandPrimary = Color(red: 0.263, green: 0.914, blue: 0.482)
    /// 品牌辅色 #38f9d7
    static let brandSecondary = Color(red: 0.220, green: 0.976, blue: 0.843)
    /// 删除/警告红 #FF453A
    static let destructiveRed = Color(red: 1.0, green: 0.271, blue: 0.227)
    /// 存储警告黄 #F4C542
    static let warningYellow = Color(red: 0.957, green: 0.773, blue: 0.259)
    /// 深色背景 #111111
    static let appBackground = Color(red: 0.067, green: 0.067, blue: 0.067)
    /// 卡片/区块背景
    static let surfaceBackground = Color.white.opacity(0.06)
    /// 次要文字 #888888
    static let textSecondary = Color(red: 0.533, green: 0.533, blue: 0.533)
    /// 辅助文字 #555555
    static let textMuted = Color(red: 0.333, green: 0.333, blue: 0.333)
}

// MARK: - 品牌渐变

extension LinearGradient {
    /// 品牌主渐变（135°）
    static let brandGradient = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 间距系统

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    /// 页面左右边距
    static let pagePadding: CGFloat = 16
}

// MARK: - 圆角系统

enum CornerRadius {
    static let hero: CGFloat = 22
    static let card: CGFloat = 16
    static let button: CGFloat = 14
    static let thumbnail: CGFloat = 8
    static let chip: CGFloat = 12
    static let progressBar: CGFloat = 2
}

// MARK: - 共享视图组件

/// 品牌渐变主按钮
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
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

/// 红色删除按钮
struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.destructiveRed)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
    }
}

/// 卡片容器
struct CardContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

/// 文件大小格式化
func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
