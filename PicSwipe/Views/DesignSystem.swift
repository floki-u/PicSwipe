// PicSwipe/Views/DesignSystem.swift
import SwiftUI

// MARK: - 品牌色（Dungeon Pixel 主题 · Light/Dark 自适应）

extension Color {
    /// 品牌主色 — Dark: 柔青绿 #5DE6C8 / Light: 深青绿 #2D9B85
    static let brandPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.365, green: 0.902, blue: 0.784, alpha: 1)
            : UIColor(red: 0.176, green: 0.608, blue: 0.522, alpha: 1)
    })
    /// 品牌辅色 — Dark: #3BAA92 / Light: #24816F
    static let brandSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.667, blue: 0.573, alpha: 1)
            : UIColor(red: 0.141, green: 0.506, blue: 0.435, alpha: 1)
    })
    /// 删除/警告红 — Dark: #C0392B / Light: #B22C1F
    static let destructiveRed = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.753, green: 0.224, blue: 0.169, alpha: 1)
            : UIColor(red: 0.698, green: 0.173, blue: 0.122, alpha: 1)
    })
    /// 存储警告/XP 琥珀 — Dark: #F0C674 / Light: #C89520
    static let warningYellow = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.776, blue: 0.455, alpha: 1)
            : UIColor(red: 0.784, green: 0.584, blue: 0.125, alpha: 1)
    })
    /// 深藏青背景 — Dark: #12101F / Light: #F5F2EB（暖羊皮纸）
    static let appBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.063, blue: 0.122, alpha: 1)
            : UIColor(red: 0.961, green: 0.949, blue: 0.922, alpha: 1)
    })
    /// 卡片/区块背景 — Dark: white@5% / Light: #EFECE5
    static let surfaceBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.05)
            : UIColor(red: 0.937, green: 0.925, blue: 0.898, alpha: 1)
    })
    /// 次要文字 — Dark: #7A7A8E / Light: #71717A
    static let textSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.478, green: 0.478, blue: 0.557, alpha: 1)
            : UIColor(red: 0.443, green: 0.443, blue: 0.478, alpha: 1)
    })
    /// 辅助文字 — Dark: #4A4A5E / Light: #A0A0A8
    static let textMuted = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.290, green: 0.290, blue: 0.369, alpha: 1)
            : UIColor(red: 0.627, green: 0.627, blue: 0.659, alpha: 1)
    })

    // MARK: - 语义 Token（15 个新增）

    /// 主文字 — Dark: #FFFFFF / Light: #1A1830
    static let textPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 1)
    })
    /// 媒体叠加文字 — 始终白色（照片/视频上方）
    static let textOnMedia = Color.white

    /// 卡片底色 — Dark: white@5% / Light: brandPrimary@4%
    static let fillSubtle = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.05)
            : UIColor(red: 0.176, green: 0.608, blue: 0.522, alpha: 0.04)
    })
    /// 徽章/未选中按钮 — Dark: white@10% / Light: #1A1830@6%
    static let fillTertiary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.06)
    })
    /// 撤回按钮底色 — Dark: white@15% / Light: #1A1830@10%
    static let fillSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.10)
    })

    /// 弱边框 — Dark: white@10% / Light: #1A1830@10%
    static let borderSubtle = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.10)
    })
    /// ESC/HOME 按钮边框 — Dark: white@20% / Light: #1A1830@15%
    static let borderMedium = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.20)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.15)
    })

    /// 分割线 — Dark: white@8% / Light: #1A1830@8%
    static let divider = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.08)
    })
    /// FilterView 浅分割线 — Dark: white@6% / Light: #1A1830@6%
    static let dividerLight = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.06)
    })

    /// 未激活页面点 — Dark: white@30% / Light: #1A1830@20%
    static let indicatorInactive = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.30)
            : UIColor(red: 0.102, green: 0.094, blue: 0.188, alpha: 0.20)
    })

    /// 加载遮罩 — Dark: black@50% / Light: black@40%
    static let overlayScrim = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.50)
            : UIColor.black.withAlphaComponent(0.40)
    })
    /// 预览卡底部渐变 — Dark: black@70% / Light: black@60%
    static let overlayHeavy = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.70)
            : UIColor.black.withAlphaComponent(0.60)
    })
    /// 按钮叠加背景 — Dark: black@40% / Light: black@30%
    static let overlayMedium = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.40)
            : UIColor.black.withAlphaComponent(0.30)
    })

    /// DungeonCard 底色 — Dark: brandPrimary@3% / Light: brandPrimary@6%
    static let cardGlowBackground = Color(UIColor { tc in
        if tc.userInterfaceStyle == .dark {
            return UIColor(red: 0.365, green: 0.902, blue: 0.784, alpha: 0.03)
        } else {
            return UIColor(red: 0.176, green: 0.608, blue: 0.522, alpha: 0.06)
        }
    })
    /// DungeonCard 边框 — Dark: brandPrimary@20% / Light: brandPrimary@30%
    static let cardBorder = Color(UIColor { tc in
        if tc.userInterfaceStyle == .dark {
            return UIColor(red: 0.365, green: 0.902, blue: 0.784, alpha: 0.20)
        } else {
            return UIColor(red: 0.176, green: 0.608, blue: 0.522, alpha: 0.30)
        }
    })
}

// MARK: - 像素字体

extension Font {
    /// 像素字体 — 用于标题、按钮标签、数字等 RPG 元素
    /// Press Start 2P 不支持中文，中文内容请使用系统字体
    static func pixel(_ size: CGFloat) -> Font {
        .custom("PressStart2P-Regular", size: size)
    }
}

// MARK: - 品牌渐变（Dungeon 青绿 -> 深青）

extension LinearGradient {
    /// 品牌主渐变（135 deg）— 青绿 -> 深青
    static let brandGradient = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 删除红渐变 — destructiveRed -> destructiveRed@78%（自适应）
    static let destructiveGradient = LinearGradient(
        colors: [
            .destructiveRed,
            .destructiveRed.opacity(0.78)
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
            .background(Color.cardGlowBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.cardBorder, lineWidth: 1)
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
            .background(Color.cardGlowBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.cardBorder, lineWidth: 1)
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
                    .fill(isFilled ? barColor : Color.fillTertiary)
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
