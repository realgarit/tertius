import Foundation
import Domain
import Application

/// Persists ``AppSettings`` as JSON in `UserDefaults`. The Domain and use cases
/// never see `UserDefaults` — they depend only on the `ConfigStore` port.
public final class UserDefaultsConfigStore: ConfigStore {
    public static let storageKey = "settings.v1"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        guard
            let data = defaults.data(forKey: Self.storageKey),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    public func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
