// PicSwipe/Views/Onboarding/OnboardingFlow.swift
import SwiftUI
import SwiftData
import Photos

/// 引导流程管理器
/// 按顺序展示：欢迎页 → 权限申请页 → 手势教程
struct OnboardingFlow: View {
    @Binding var showOnboarding: Bool

    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var step: OnboardingStep = .welcome

    private enum OnboardingStep {
        case welcome
        case permission
        case tutorial
    }

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView {
                advanceToPermissionStep()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))

        case .permission:
            PermissionView(
                onAuthorized: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .tutorial
                    }
                },
                onSkip: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .tutorial
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))

        case .tutorial:
            TutorialView {
                showOnboarding = false
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
        }
    }

    // MARK: - 流程推进

    private func advanceToPermissionStep() {
        let status = photoService.authorizationStatus
        withAnimation(.easeInOut(duration: 0.3)) {
            if status == .notDetermined {
                // 未请求过权限 → 显示权限页
                step = .permission
            } else {
                // 已有结果 → 直接检查是否需要教程
                checkTutorialStep()
            }
        }
    }

    private func checkTutorialStep() {
        let settings = statsService.getSettings(in: modelContext)
        if settings.hasSeenTutorial {
            showOnboarding = false
        } else {
            step = .tutorial
        }
    }
}
