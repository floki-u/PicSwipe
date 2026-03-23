import Foundation

enum AppDestination: Hashable {
    case swipe(CleanMode)
    case confirmDelete
    case filter
    case settings
    case result(deletedCount: Int, freedSpace: Int64, mode: CleanMode)
}
