import Foundation
import Observation

// MARK: - StorageInfo

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64

    var availableSpace: Int64 { totalSpace - usedSpace }

    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    var level: StorageLevel {
        switch usagePercentage {
        case ..<0.7: return .normal
        case 0.7..<0.9: return .warning
        default: return .critical
        }
    }
}

// MARK: - StorageLevel

enum StorageLevel: Equatable {
    case normal, warning, critical
}

// MARK: - StorageService

@Observable
final class StorageService {
    var storageInfo: StorageInfo = StorageInfo(totalSpace: 0, usedSpace: 0)

    func fetchStorageInfo() -> StorageInfo {
        let fileManager = FileManager.default
        guard let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attrs[.systemSize] as? Int64,
              let freeSize = attrs[.systemFreeSize] as? Int64 else {
            return StorageInfo(totalSpace: 0, usedSpace: 0)
        }
        let info = StorageInfo(totalSpace: totalSize, usedSpace: totalSize - freeSize)
        storageInfo = info
        return info
    }
}
