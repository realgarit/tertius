import Foundation

/// A minimal semantic version for comparing the running build against the latest
/// GitHub release. Pure value type; pre-release suffixes are ignored for ordering.
public struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String { "\(major).\(minor).\(patch)" }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses `X`, `X.Y`, or `X.Y.Z` (with an optional leading `v` and an
    /// ignored `-suffix`). Returns nil if the major component is not numeric.
    public init?(_ string: String) {
        var s = string.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("v") || s.hasPrefix("V") { s.removeFirst() }
        guard !s.isEmpty else { return nil }

        let core = s.split(separator: "-", maxSplits: 1).first.map(String.init) ?? s
        let parts = core.split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        func component(_ index: Int) -> Int? {
            guard index < parts.count else { return 0 }
            return Int(parts[index])
        }

        guard let major = component(0), let minor = component(1), let patch = component(2) else {
            return nil
        }
        self.init(major: major, minor: minor, patch: patch)
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
