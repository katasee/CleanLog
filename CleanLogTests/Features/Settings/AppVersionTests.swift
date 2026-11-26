import Foundation
import Testing

@testable import CleanLog

struct AppVersionTests {
    @Test func readsTheAppBundle() {
        let version = AppVersion(bundle: .main)
        #expect(version.number == Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        #expect(version.build == Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
    }

    @Test func fallsBackToZeroWithoutAVersion() throws {
        let bundle = try #require(Bundle(path: FileManager.default.temporaryDirectory.path))
        #expect(AppVersion(bundle: bundle) == AppVersion(number: "0", build: "0"))
    }
}
