import Domain

public enum UpdateCheckError: Error {
    case unparseableVersion
}

public struct UpdateCheckResult: Sendable, Equatable {
    public let current: SemanticVersion
    public let latest: SemanticVersion

    public var isUpdateAvailable: Bool { latest > current }
}

/// Compares the running build against the latest released version.
public struct CheckForUpdatesUseCase: Sendable {
    private let checker: UpdateChecking
    private let currentVersion: String

    public init(checker: UpdateChecking, currentVersion: String) {
        self.checker = checker
        self.currentVersion = currentVersion
    }

    public func check() async throws -> UpdateCheckResult {
        let latestString = try await checker.latestVersion()
        guard
            let latest = SemanticVersion(latestString),
            let current = SemanticVersion(currentVersion)
        else {
            throw UpdateCheckError.unparseableVersion
        }
        return UpdateCheckResult(current: current, latest: latest)
    }
}
