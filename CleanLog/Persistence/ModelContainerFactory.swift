import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: CleanLogMigrationPlan.self,
            configurations: configuration
        )
    }
}
