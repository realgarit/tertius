import Testing
@testable import Application

@Suite("Application scaffold")
struct ApplicationScaffoldTests {
    @Test("target compiles and links")
    func compiles() {
        // Real use-case tests arrive in M2/M3.
        #expect(Bool(true))
    }
}
