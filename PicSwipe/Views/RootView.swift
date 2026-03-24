// PicSwipe/Views/RootView.swift
import SwiftUI
import SwiftData
import Photos

struct RootView: View {
    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StorageService.self) private var storageService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var path = NavigationPath()
    @State private var cleanSession: CleanSession?
    @State private var showOnboarding: Bool = true

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow(showOnboarding: $showOnboarding)
            } else if photoService.authorizationStatus == .denied
                        || photoService.authorizationStatus == .restricted {
                PermissionDeniedView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(
                        path: $path,
                        cleanSession: $cleanSession
                    )
                    .navigationDestination(for: AppDestination.self) { destination in
                        switch destination {
                        case .swipe(let mode):
                            SwipeView(
                                path: $path,
                                cleanSession: $cleanSession,
                                mode: mode
                            )
                        case .confirmDelete:
                            ConfirmDeleteView(
                                path: $path,
                                cleanSession: $cleanSession
                            )
                        case .result(let deletedCount, let freedSpace, let mode):
                            ResultView(
                                path: $path,
                                cleanSession: $cleanSession,
                                deletedCount: deletedCount,
                                freedSpace: freedSpace,
                                mode: mode
                            )
                        case .settings:
                            SettingsView(path: $path)
                        case .filter(let mode):
                            FilterView(
                                path: $path,
                                cleanSession: $cleanSession,
                                mode: mode
                            )
                        case .swipeWithFilter(let mode, let filter):
                            SwipeView(
                                path: $path,
                                cleanSession: $cleanSession,
                                mode: mode,
                                filter: filter
                            )
                        }
                    }
                }
            }
        }
        .task {
            checkOnboardingStatus()
        }
        .onChange(of: path) { _, _ in
            // 当导航栈变化时（例如从设置页返回首页），重新检查 onboarding 状态
            checkOnboardingStatus()
        }
    }

    // MARK: - 引导状态检查

    private func checkOnboardingStatus() {
        let settings = statsService.getSettings(in: modelContext)
        let authStatus = photoService.authorizationStatus

        // 已有权限且已看过教程 → 跳过引导
        if (authStatus == .authorized || authStatus == .limited) && settings.hasSeenTutorial {
            showOnboarding = false
        } else if !settings.hasSeenTutorial {
            // 教程未看过 → 显示引导（用于重播教程场景）
            showOnboarding = true
        }
    }
}
