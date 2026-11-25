protocol Pasteboard: AnyObject {
    func copy(_ text: String)
}

#if DEBUG
    final class FakePasteboard: Pasteboard {
        private(set) var copied: [String] = []

        func copy(_ text: String) {
            copied.append(text)
        }
    }
#endif
