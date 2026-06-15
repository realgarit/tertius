import Testing
@testable import Infrastructure

@Suite("Infrastructure scaffold")
struct InfrastructureScaffoldTests {
    @Test("target compiles and links")
    func compiles() {
        // Adapter-level tests (where headless-testable) arrive in M2.
        #expect(Bool(true))
    }
}
