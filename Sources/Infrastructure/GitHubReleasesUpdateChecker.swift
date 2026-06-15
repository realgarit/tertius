import Foundation
import Application

/// Reads the latest released version from the GitHub Releases API. The network
/// call is a thin shell; the tag→version parsing is factored out and unit-tested.
public final class GitHubReleasesUpdateChecker: UpdateChecking {
    private let owner: String
    private let repo: String
    private let session: URLSession

    public init(owner: String = "realgarit", repo: String = "tertius", session: URLSession = .shared) {
        self.owner = owner
        self.repo = repo
        self.session = session
    }

    public func latestVersion() async throws -> String {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await session.data(for: request)
        return try Self.version(fromReleaseJSON: data)
    }

    struct Release: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }

    static func version(fromReleaseJSON data: Data) throws -> String {
        let release = try JSONDecoder().decode(Release.self, from: data)
        return stripLeadingV(release.tagName)
    }

    static func stripLeadingV(_ tag: String) -> String {
        (tag.hasPrefix("v") || tag.hasPrefix("V")) ? String(tag.dropFirst()) : tag
    }
}
