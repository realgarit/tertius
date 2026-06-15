import Testing
@testable import Domain

@Suite("TertiusInfo")
struct TertiusInfoTests {
    @Test("bundle identifier is the locked TCC-keyed value")
    func bundleIdentifierIsLocked() {
        // This value is part of the codesign designated requirement.
        // If this test fails, the Accessibility grant will break for users.
        #expect(TertiusInfo.bundleIdentifier == "io.github.realgarit.tertius")
    }

    @Test("display name is Tertius")
    func displayName() {
        #expect(TertiusInfo.displayName == "Tertius")
    }
}
