// PicSwipe/Views/DesignSystem.swift
import SwiftUI

// MARK: - 品牌色（Dungeon Pixel 主题）

extension Color {
    /// 品牌主色 — 柔青绿 #5DE6C8
    static let brandPrimary = Color(red: 0.365, green: 0.902, blue: 0.784)
    /// 品牌辅色 — 深青 #3BAA92
    static let brandSecondary = Color(red: 0.231, green: 0.667, blue: 0.573)
    /// 删除/警告红 — 深红 #C0392B
    static let destructiveRed = Color(red: 0.753, green: 0.224, blue: 0.169)
    /// 存储警告/XP 琥珀 #F0C674
    static let warningYellow = Color(red: 0.941, green: 0.776, blue: 0.455)
    /// 深藏青背景 #12101F
    static let appBackground = Color(red: 0.071, green: 0.063, blue: 0.122)
    /// 卡片/区块背景
    static let surfaceBackground = Color.white.opacity(0.05)
    /// 次要文字 — 偏蓝灰 #7A7A8E
    static let textSecondary = Color(red: 0.478, green: 0.478, blue: 0.557)
    /// 辅助文字 — 偏蓝灰 #4A4A5E
    static let textMuted = Color(red: 0.290, green: 0.290, blue: 0.369)
}

// MARK: - 像素字体

extension Font {
    /// 像素字体 — 用于标题、按钮标签、数字等 RPG 元素
    /// Press Start 2P 不支持中文，中文内容请使用系统字体
    static func pixel(_ size: CGFloat) -> Font {
        .custom("PressStart2P-Regular", size: size)
    }
}

// MARK: - 品牌渐变（Dungeon 青绿→深青）

extension LinearGradient {
    /// 品牌主渐变（135°）— 青绿→深青
    static let brandGradient = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 删除红渐变 — #C0392B → #96281B
    static let destructiveGradient = LinearGradient(
        colors: [
            Color(red: 0.753, green: 0.224, blue: 0.169),
            Color(red: 0.588, green: 0.157, blue: 0.106)
        ],
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

/// 品牌主按钮 — 地牢边框发光风格
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pixel(10))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(Color.brandPrimary, lineWidth: 1.5)
                )
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 2)
        }
    }
}

/// 红色删除按钮 — 地牢边框发光风格
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
                .background(LinearGradient.destructiveGradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(Color.destructiveRed.opacity(0.6), lineWidth: 1)
                )
        }
    }
}

/// 地牢风格卡片容器 — 边框式代替填充式
struct DungeonCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(Color.brandPrimary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
            )
    }
}

/// 原有卡片容器（兼容用）
struct CardContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(Color.brandPrimary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
            )
    }
}

/// RPG 风格分段 HP 条 — 替换连续进度条
struct HPBar: View {
    let usagePercent: Double
    let segmentCount: Int

    init(usagePercent: Double, segmentCount: Int = 10) {
        self.usagePercent = usagePercent
        self.segmentCount = segmentCount
    }

    /// 根据使用百分比返回颜色
    private var barColor: Color {
        let remaining = 1.0 - usagePercent
        switch remaining {
        case 0.3...: return .brandPrimary
        case 0.1..<0.3: return .warningYellow
        default: return .destructiveRed
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<segmentCount, id: \.self) { index in
                let threshold = Double(index) / Double(segmentCount)
                let isFilled = usagePercent > threshold

                RoundedRectangle(cornerRadius: 2)
                    .fill(isFilled ? barColor : Color.white.opacity(0.1))
                    .frame(height: 14)
            }
        }
    }
}

/// 文件大小格式化
func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
