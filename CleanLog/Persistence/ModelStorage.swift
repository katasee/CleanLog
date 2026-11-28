import SwiftData

nonisolated enum ModelStorage: Sendable, Equatable {
    case inMemory
    case onDevice
    case iCloud(containerID: String)

    func configuration(for schema: Schema) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: self == .inMemory,
            cloudKitDatabase: cloudKitDatabase
        )
    }

    private var cloudKitDatabase: ModelConfiguration.CloudKitDatabase {
        switch self {
        case .inMemory, .onDevice:
            .none
        case .iCloud(let containerID):
            .private(containerID)
        }
    }
}
