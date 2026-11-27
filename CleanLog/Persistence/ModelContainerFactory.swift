import SwiftData

enum ModelContainerFactory {
    static func make(_ storage: ModelStorage) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        return try ModelContainer(
            for: schema,
            migrationPlan: CleanLogMigrationPlan.self,
            configurations: storage.configuration(for: schema)
        )
    }
}
