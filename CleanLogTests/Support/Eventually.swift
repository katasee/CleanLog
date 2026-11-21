import Testing

private let maxYields = 1_000

func eventually(
    _ condition: () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<maxYields {
        if condition() {
            return
        }
        await Task.yield()
    }
    Issue.record("condition never held", sourceLocation: sourceLocation)
}
