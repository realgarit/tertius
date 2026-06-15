import Domain

/// Single source of truth for the current ``AppSettings``. Loads from the
/// ``ConfigStore`` on init, persists on every mutation, and notifies an
/// observer. Framework-free so it is fully unit-testable; the SwiftUI layer
/// wraps it for the UI.
public final class SettingsStore {
    public private(set) var settings: AppSettings
    private let config: ConfigStore
    private let onChange: ((AppSettings) -> Void)?

    public init(config: ConfigStore, onChange: ((AppSettings) -> Void)? = nil) {
        self.config = config
        self.onChange = onChange
        self.settings = config.load()
    }

    /// Apply a mutation, persist it, and notify.
    public func update(_ mutate: (inout AppSettings) -> Void) {
        mutate(&settings)
        config.save(settings)
        onChange?(settings)
    }
}

/// Toggles the macOS login-item registration.
public struct ManageLaunchAtLoginUseCase {
    private let manager: LaunchAtLoginManaging

    public init(manager: LaunchAtLoginManaging) {
        self.manager = manager
    }

    public var isEnabled: Bool { manager.isEnabled }

    public func apply(_ enabled: Bool) throws {
        try manager.setEnabled(enabled)
    }
}
