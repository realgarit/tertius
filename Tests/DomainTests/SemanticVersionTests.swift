import Testing
@testable import Domain

@Suite("SemanticVersion")
struct SemanticVersionTests {
    @Test("parses X.Y.Z")
    func parsesFull() {
        let v = SemanticVersion("1.2.3")
        #expect(v == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("tolerates a leading v")
    func toleratesV() {
        #expect(SemanticVersion("v0.1.1") == SemanticVersion(major: 0, minor: 1, patch: 1))
    }

    @Test("defaults a missing patch to 0")
    func missingPatch() {
        #expect(SemanticVersion("1.2") == SemanticVersion(major: 1, minor: 2, patch: 0))
    }

    @Test("ignores a pre-release suffix on the patch")
    func ignoresSuffix() {
        #expect(SemanticVersion("1.2.3-beta.1") == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("returns nil for nonsense")
    func rejectsGarbage() {
        #expect(SemanticVersion("not-a-version") == nil)
        #expect(SemanticVersion("") == nil)
    }

    @Test("description renders X.Y.Z")
    func describes() {
        #expect(SemanticVersion("1.2.3")!.description == "1.2.3")
    }

    @Test("orders by major, then minor, then patch")
    func ordering() {
        #expect(SemanticVersion("0.1.2")! > SemanticVersion("0.1.1")!)
        #expect(SemanticVersion("0.2.0")! > SemanticVersion("0.1.9")!)
        #expect(SemanticVersion("1.0.0")! > SemanticVersion("0.9.9")!)
        #expect(SemanticVersion("1.2.3")! == SemanticVersion("1.2.3")!)
        #expect(!(SemanticVersion("1.2.3")! > SemanticVersion("1.2.3")!))
    }
}
