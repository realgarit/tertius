import Testing
import Foundation
@testable import Infrastructure
import Domain

@Suite("UserDefaultsConfigStore")
struct UserDefaultsConfigStoreTests {
    /// An isolated, ephemeral defaults domain per test.
    private func isolatedDefaults() -> UserDefaults {
        let suite = "tertius.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test("loads defaults when nothing is stored")
    func loadsDefaultWhenEmpty() {
        let store = UserDefaultsConfigStore(defaults: isolatedDefaults())
        #expect(store.load() == .default)
    }

    @Test("saves and reloads settings unchanged")
    func roundTrips() {
        let defaults = isolatedDefaults()
        let store = UserDefaultsConfigStore(defaults: defaults)

        var settings = AppSettings.default
        settings.modifier = .command
        settings.sensitivity = 4.2
        settings.invertY = true
        settings.enabled = false
        store.save(settings)

        // A fresh store over the same defaults reads it back.
        let reloaded = UserDefaultsConfigStore(defaults: defaults).load()
        #expect(reloaded == settings)
    }

    @Test("falls back to defaults on corrupt data")
    func corruptDataFallsBack() {
        let defaults = isolatedDefaults()
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: UserDefaultsConfigStore.storageKey)

        let store = UserDefaultsConfigStore(defaults: defaults)
        #expect(store.load() == .default)
    }
}
