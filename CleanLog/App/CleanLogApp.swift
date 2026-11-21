import SwiftUI

@main
struct CleanLogApp: App {
    @State private var dependencies: AppDependencies

    init() {
        do {
            _dependencies = State(initialValue: try AppDependencies.live())
        } catch {
            preconditionFailure("Could not open the store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
        }
    }
}
