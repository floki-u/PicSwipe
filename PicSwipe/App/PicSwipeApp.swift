import SwiftUI
import SwiftData

@main
struct PicSwipeApp: App {
    let modelContainer: ModelContainer
    let photoService = PhotoLibraryService()
    let storageService = StorageService()
    let statsService = StatisticsService()

    init() {
        do {
            let schema = Schema([CleanRecord.self, UserSettings.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(photoService)
                .environment(storageService)
                .environment(statsService)
        }
        .modelContainer(modelContainer)
    }
}
