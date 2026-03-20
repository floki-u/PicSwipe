import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(PhotoLibraryService.self) private var photoService
    @Environment(StorageService.self) private var storageService
    @Environment(StatisticsService.self) private var statsService
    @Environment(\.modelContext) private var modelContext

    @State private var path = NavigationPath()
    @State private var cleanSession: CleanSession?

    var body: some View {
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
        .preferredColorScheme(.dark)
    }
}
