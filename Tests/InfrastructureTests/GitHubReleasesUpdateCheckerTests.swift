import Testing
import Foundation
@testable import Infrastructure

@Suite("GitHubReleasesUpdateChecker parsing")
struct GitHubReleasesUpdateCheckerTests {
    @Test("extracts the version from a releases-latest payload, stripping the v")
    func parsesTag() throws {
        let json = Data(#"{"tag_name":"v0.3.0","name":"v0.3.0"}"#.utf8)
        #expect(try GitHubReleasesUpdateChecker.version(fromReleaseJSON: json) == "0.3.0")
    }

    @Test("leaves a tag without a leading v unchanged")
    func noLeadingV() throws {
        let json = Data(#"{"tag_name":"1.4.2"}"#.utf8)
        #expect(try GitHubReleasesUpdateChecker.version(fromReleaseJSON: json) == "1.4.2")
    }

    @Test("throws on malformed JSON")
    func throwsOnBadJSON() {
        let json = Data("not json".utf8)
        #expect(throws: Error.self) { try GitHubReleasesUpdateChecker.version(fromReleaseJSON: json) }
    }
}
