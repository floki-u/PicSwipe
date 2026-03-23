import Foundation

enum AppDestination: Hashable {
    case swipe(CleanMode)
    case swipeWithFilter(CleanMode, FilterCriteria)
    case confirmDelete
    case filter(CleanMode)
    case settings
    case result(deletedCount: Int, freedSpace: Int64, mode: CleanMode)
}
