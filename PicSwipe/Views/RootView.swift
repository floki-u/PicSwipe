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
                        case .result(let deletedCount, let freedSpace):
                            ResultView(
                                path: $path,
                                cleanSession: $cleanSession,
                                deletedCount: deletedCount,
                                freedSpace: freedSpace
                            )
                        case .settings:
                            SettingsView()
                        case .filter:
                            EmptyView() // V1.1
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
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
        }
    }
}
