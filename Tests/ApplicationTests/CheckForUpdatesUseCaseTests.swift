import Testing
@testable import Application
import Domain

@Suite("CheckForUpdatesUseCase")
struct CheckForUpdatesUseCaseTests {
    struct FakeChecker: UpdateChecking {
        let version: String
        func latestVersion() async throws -> String { version }
    }

    struct ThrowingChecker: UpdateChecking {
        struct Boom: Error {}
        func latestVersion() async throws -> String { throw Boom() }
    }

    @Test("reports an update available when the latest is newer")
    func updateAvailable() async throws {
        let useCase = CheckForUpdatesUseCase(checker: FakeChecker(version: "0.2.0"), currentVersion: "0.1.1")
        let result = try await useCase.check()
        #expect(result.isUpdateAvailable == true)
        #expect(result.latest == SemanticVersion("0.2.0"))
    }

    @Test("reports up to date when versions match")
    func upToDate() async throws {
        let useCase = CheckForUpdatesUseCase(checker: FakeChecker(version: "v0.1.1"), currentVersion: "0.1.1")
        let result = try await useCase.check()
        #expect(result.isUpdateAvailable == false)
    }

    @Test("reports up to date when the running build is newer than the latest release")
    func runningNewer() async throws {
        let useCase = CheckForUpdatesUseCase(checker: FakeChecker(version: "0.1.0"), currentVersion: "0.2.0")
        let result = try await useCase.check()
        #expect(result.isUpdateAvailable == false)
    }

    @Test("throws on an unparseable latest version")
    func unparseable() async {
        let useCase = CheckForUpdatesUseCase(checker: FakeChecker(version: "garbage"), currentVersion: "0.1.0")
        await #expect(throws: Error.self) { try await useCase.check() }
    }

    @Test("propagates the checker's error")
    func propagatesError() async {
        let useCase = CheckForUpdatesUseCase(checker: ThrowingChecker(), currentVersion: "0.1.0")
        await #expect(throws: Error.self) { try await useCase.check() }
    }
}
