import Domain

/// Ports — the interfaces the Application layer depends on. Infrastructure
/// provides the concrete adapters; the Domain and use cases never import a
/// framework. Source dependencies point inward only.

/// Source of normalized trackpad input. Abstracts the `CGEventTap`.
///
/// The handler is called synchronously for each sample and returns whether the
/// underlying OS event should be **swallowed** (so it does not also scroll/zoom).
public protocol InputSource: AnyObject {
    /// Synchronous per-sample handler. Returns `true` to swallow the event.
    var onSample: ((GestureSample) -> Bool)? { get set }
    func start() throws
    func stop()
}

/// Performs synthetic middle-button actions. Abstracts CGEvent posting.
public protocol PointerActuator {
    func perform(_ command: PointerCommand)
}

/// Loads and saves user settings. Abstracts `UserDefaults`.
public protocol ConfigStore {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

/// Queries and requests the permissions needed to tap and post events.
public protocol AccessibilityAuthorizing {
    /// True when the app may both observe (active tap) and post events.
    var isTrusted: Bool { get }
    /// Prompt the user and/or deep-link to System Settings.
    func requestAccess()
}

/// Manages the macOS "launch at login" registration. Abstracts `SMAppService`.
public protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// Fetches the latest released version string (e.g. "0.1.2"). Abstracts the
/// GitHub Releases API. Sendable so the use case can run off the main actor.
public protocol UpdateChecking: Sendable {
    func latestVersion() async throws -> String
}
